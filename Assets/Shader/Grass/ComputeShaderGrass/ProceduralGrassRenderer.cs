// MIT License

// Copyright (c) 2020 NedMakesGames

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class ProceduralGrassRenderer : MonoBehaviour
{

    // A class to hold grass settings
    [System.Serializable]
    public class GrassSettings
    {
        [Tooltip("The maximim number of grass segments. Note this is also bounded by the max value set in the compute shader")]
        public int maxSegments = 3;
        [Tooltip("The maximum bend of a blade of grass, as a multiplier to 90 degrees")]
        public float maxBendAngle = 0;
        [Tooltip("The blade curvature shape")]
        public float bladeCurvature = 1;
        [Tooltip("The base height of a blade")]
        public float bladeHeight = 1;
        [Tooltip("The height variance of a blade")]
        public float bladeHeightVariance = 0.1f;
        [Tooltip("The base width of a blade")]
        public float bladeWidth = 1;
        [Tooltip("The width variance of a blade")]
        public float bladeWidthVariance = 0.1f;
        [Tooltip("A noise texture to control wind offsets. The red and green channels become x and z offsets in world position")]
        public Texture2D windNoiseTexture = null;
        [Tooltip("The scale of the wind texture")]
        public float windTextureScale = 1;
        [Tooltip("A multiplier to time when creating the wind texture UV")]
        public float windPeriod = 1;
        [Tooltip("A multiplier to world space XZ when creating the wind texture UV")]
        public float windScale = 1;
        [Tooltip("The maximim wind offset length")]
        public float windAmplitude = 0;
    }

    [Tooltip("A mesh to create grass from. A blade sprouts from the center of every triangle")]
    [SerializeField] private Mesh sourceMesh = default;
    [Tooltip("The grass geometry creating compute shader")]
    [SerializeField] private ComputeShader grassComputeShader = default;
    [Tooltip("The material to render the grass mesh")]
    [SerializeField] private Material material = default;

    [SerializeField] private GrassSettings grassSettings = default;

    // The structure to send to the compute shader
    // This layout kind assures that the data is laid out sequentially
    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    private struct SourceVertex
    {
        public Vector3 position;
    }

    // A state variable to help keep track of whether compute buffers have been set up
    private bool initialized;
    // A compute buffer to hold vertex data of the source mesh
    private ComputeBuffer sourceVertBuffer;
    // A compute buffer to hold index data of the source mesh
    private ComputeBuffer sourceTriBuffer;
    // A compute buffer to hold vertex data of the generated mesh
    private ComputeBuffer drawBuffer;
    // A compute buffer to hold indirect draw arguments
    private ComputeBuffer argsBuffer;
    // We have to instantiate the shaders so each points to their unique compute buffers
    private ComputeShader instantiatedGrassComputeShader;
    private Material instantiatedMaterial;
    // The id of the kernel in the grass compute shader
    private int idGrassKernel;
    // The x dispatch size for the grass compute shader
    private int dispatchSize;
    // The local bounds of the generated mesh
    private Bounds localBounds;

    // The size of one entry in the various compute buffers
    private const int SOURCE_VERT_STRIDE = sizeof(float) * 3;
    private const int SOURCE_TRI_STRIDE = sizeof(int);
    private const int DRAW_STRIDE = sizeof(float) * (3 + (3 + 1) * 3);
    private const int INDIRECT_ARGS_STRIDE = sizeof(int) * 4;

    // The data to reset the args buffer with every frame
    // 0: vertex count per draw instance. We will only use one instance
    // 1: instance count. One
    // 2: start vertex location if using a Graphics Buffer
    // 3: and start instance location if using a Graphics Buffer
    private int[] argsBufferReset = new int[] { 0, 1, 0, 0 };

    private void OnEnable()
    {
        Debug.Assert(grassComputeShader != null, "The grass compute shader is null", gameObject);
        Debug.Assert(material != null, "The material is null", gameObject);

        // If initialized, call on disable to clean things up
        if (initialized)
        {
            OnDisable();
        }
        initialized = true;

        // Instantiate the shaders so they can point to their own buffers
        instantiatedGrassComputeShader = Instantiate(grassComputeShader);
        instantiatedMaterial = Instantiate(material);

        // Grab data from the source mesh
        Vector3[] positions = sourceMesh.vertices;
        int[] tris = sourceMesh.triangles;

        // Create the data to upload to the source vert buffer
        SourceVertex[] vertices = new SourceVertex[positions.Length];
        for (int i = 0; i < vertices.Length; i++)
        {
            vertices[i] = new SourceVertex()
            {
                position = positions[i],
            };
        }
        int numSourceTriangles = tris.Length / 3; // The number of triangles in the source mesh is the index array / 3
        // Each grass blade segment has two points. Counting those plus the tip gives us the total number of points
        int maxBladeSegments = Mathf.Max(1, grassSettings.maxSegments);
        int maxBladeTriangles = (maxBladeSegments - 1) * 2 + 1;

        // Create compute buffers
        // The stride is the size, in bytes, each object in the buffer takes up
        sourceVertBuffer = new ComputeBuffer(vertices.Length, SOURCE_VERT_STRIDE, ComputeBufferType.Structured, ComputeBufferMode.Immutable);
        sourceVertBuffer.SetData(vertices);
        sourceTriBuffer = new ComputeBuffer(tris.Length, SOURCE_TRI_STRIDE, ComputeBufferType.Structured, ComputeBufferMode.Immutable);
        sourceTriBuffer.SetData(tris);
        drawBuffer = new ComputeBuffer(numSourceTriangles * maxBladeTriangles, DRAW_STRIDE, ComputeBufferType.Append);
        drawBuffer.SetCounterValue(0);
        argsBuffer = new ComputeBuffer(1, INDIRECT_ARGS_STRIDE, ComputeBufferType.IndirectArguments);

        // Cache the kernel IDs we will be dispatching
        idGrassKernel = instantiatedGrassComputeShader.FindKernel("Main");

        // Set data on the shaders
        instantiatedGrassComputeShader.SetBuffer(idGrassKernel, "_SourceVertices", sourceVertBuffer);
        instantiatedGrassComputeShader.SetBuffer(idGrassKernel, "_SourceTriangles", sourceTriBuffer);
        instantiatedGrassComputeShader.SetBuffer(idGrassKernel, "_DrawTriangles", drawBuffer);
        instantiatedGrassComputeShader.SetBuffer(idGrassKernel, "_IndirectArgsBuffer", argsBuffer);
        instantiatedGrassComputeShader.SetInt("_NumSourceTriangles", numSourceTriangles);
        instantiatedGrassComputeShader.SetInt("_MaxBladeSegments", maxBladeSegments);
        instantiatedGrassComputeShader.SetFloat("_MaxBendAngle", grassSettings.maxBendAngle);
        instantiatedGrassComputeShader.SetFloat("_BladeCurvature", Mathf.Max(0, grassSettings.bladeCurvature));
        instantiatedGrassComputeShader.SetFloat("_BladeHeight", grassSettings.bladeHeight);
        instantiatedGrassComputeShader.SetFloat("_BladeHeightVariance", grassSettings.bladeHeightVariance);
        instantiatedGrassComputeShader.SetFloat("_BladeWidth", grassSettings.bladeWidth);
        instantiatedGrassComputeShader.SetFloat("_BladeWidthVariance", grassSettings.bladeWidthVariance);
        instantiatedGrassComputeShader.SetTexture(idGrassKernel, "_WindNoiseTexture", grassSettings.windNoiseTexture);
        instantiatedGrassComputeShader.SetFloat("_WindTexMult", grassSettings.windTextureScale);
        instantiatedGrassComputeShader.SetFloat("_WindTimeMult", grassSettings.windPeriod);
        instantiatedGrassComputeShader.SetFloat("_WindPosMult", grassSettings.windScale);
        instantiatedGrassComputeShader.SetFloat("_WindAmplitude", grassSettings.windAmplitude);

        instantiatedMaterial.SetBuffer("_DrawTriangles", drawBuffer);

        // Calculate the number of threads to use. Get the thread size from the kernel
        // Then, divide the number of triangles by that size
        instantiatedGrassComputeShader.GetKernelThreadGroupSizes(idGrassKernel, out uint threadGroupSize, out _, out _);
        dispatchSize = Mathf.CeilToInt((float)numSourceTriangles / threadGroupSize);

        // Get the bounds of the source mesh and then expand by the maximum blade width and height
        localBounds = sourceMesh.bounds;
        localBounds.Expand(Mathf.Max(grassSettings.bladeHeight + grassSettings.bladeHeightVariance,
            grassSettings.bladeWidth + grassSettings.bladeWidthVariance));
    }

    private void OnDisable()
    {
        // Dispose of buffers and copied shaders here
        if (initialized)
        {
            // If the application is not in play mode, we have to call DestroyImmediate
            if (Application.isPlaying)
            {
                Destroy(instantiatedGrassComputeShader);
                Destroy(instantiatedMaterial);
            }
            else
            {
                DestroyImmediate(instantiatedGrassComputeShader);
                DestroyImmediate(instantiatedMaterial);
            }
            // Release each buffer
            sourceVertBuffer.Release();
            sourceTriBuffer.Release();
            drawBuffer.Release();
            argsBuffer.Release();
        }
        initialized = false;
    }

    // This applies the game object's transform to the local bounds
    // Code by benblo from https://answers.unity.com/questions/361275/cant-convert-bounds-from-world-coordinates-to-loca.html
    public Bounds TransformBounds(Bounds boundsOS)
    {
        var center = transform.TransformPoint(boundsOS.center);

        // transform the local extents' axes
        var extents = boundsOS.extents;
        var axisX = transform.TransformVector(extents.x, 0, 0);
        var axisY = transform.TransformVector(0, extents.y, 0);
        var axisZ = transform.TransformVector(0, 0, extents.z);

        // sum their absolute value to get the world extents
        extents.x = Mathf.Abs(axisX.x) + Mathf.Abs(axisY.x) + Mathf.Abs(axisZ.x);
        extents.y = Mathf.Abs(axisX.y) + Mathf.Abs(axisY.y) + Mathf.Abs(axisZ.y);
        extents.z = Mathf.Abs(axisX.z) + Mathf.Abs(axisY.z) + Mathf.Abs(axisZ.z);

        return new Bounds { center = center, extents = extents };
    }

    // LateUpdate is called after all Update calls
    private void LateUpdate()
    {
        // If in edit mode, we need to update the shaders each Update to make sure settings changes are applied
        // Don't worry, in edit mode, Update isn't called each frame
        if (Application.isPlaying == false)
        {
            OnDisable();
            OnEnable();
        }

        // Clear the draw and indirect args buffers of last frame's data
        drawBuffer.SetCounterValue(0);
        argsBuffer.SetData(argsBufferReset);

        // Transform the bounds to world space
        Bounds bounds = TransformBounds(localBounds);

        // Update the shader with frame specific data
        instantiatedGrassComputeShader.SetVector("_Time", new Vector4(0, Time.timeSinceLevelLoad, 0, 0));
        instantiatedGrassComputeShader.SetMatrix("_LocalToWorld", transform.localToWorldMatrix);

        // Dispatch the grass shader. It will run on the GPU
        instantiatedGrassComputeShader.Dispatch(idGrassKernel, dispatchSize, 1, 1);

        // DrawProceduralIndirect queues a draw call up for our generated mesh
        Graphics.DrawProceduralIndirect(instantiatedMaterial, bounds, MeshTopology.Triangles, argsBuffer, 0,
            null, null, ShadowCastingMode.Off, true, gameObject.layer);
    }
}