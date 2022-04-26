using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScannerEffect : MonoBehaviour
{
    //扫描的起点，扫描线材质(预处理材质)，已扫描距离
    public Transform ScannerOrigin;
    public Material EffectMaterial;
    public float ScanDistance;
    public float ScanSpeed = 50;

    private Camera mCamera;
    private bool scanning;
    // Update is called once per frame
    void Update()
    {
        if (scanning)
        {
            ScanDistance += Time.deltaTime * ScanSpeed;
        }

        //按下R键重置距离
        if (Input.GetKeyDown(KeyCode.R))
        {
            scanning = true;
            ScanDistance = 0f;
        }

        //鼠标左键单击，射线检测获得世界坐标然后设置起点
        if (Input.GetMouseButtonDown(0))
        {
            Ray ray = mCamera.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;
            if (Physics.Raycast(ray, out hit))
            {
                scanning = true;
                ScanDistance = 4;
                ScannerOrigin.position = hit.point;
            }
        }
    }

    private void OnEnable()
    {
        mCamera = GetComponent<Camera>();
    }

    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        EffectMaterial.SetVector("_WorldSpaceScannerPos", ScannerOrigin.position);
        EffectMaterial.SetFloat("_ScanDistance", ScanDistance);
        RaycastCornerBlit(source, destination, EffectMaterial);
    }

    private void RaycastCornerBlit(RenderTexture source, RenderTexture destination, Material material)
    {
        // Compute Frustum Corners
        float camFar = mCamera.farClipPlane;
        float camFov = mCamera.fieldOfView;
        float camAspect = mCamera.aspect;

        float fovWHalf = camFov * 0.5f;

        Vector3 toRight = mCamera.transform.right * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * camAspect;
        Vector3 toTop = mCamera.transform.up * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 topLeft = (mCamera.transform.forward - toRight + toTop);
        float camScale = topLeft.magnitude * camFar;

        topLeft.Normalize();
        topLeft *= camScale;

        Vector3 topRight = (mCamera.transform.forward + toRight + toTop);
        topRight.Normalize();
        topRight *= camScale;

        Vector3 bottomRight = (mCamera.transform.forward + toRight - toTop);
        bottomRight.Normalize();
        bottomRight *= camScale;

        Vector3 bottomLeft = (mCamera.transform.forward - toRight - toTop);
        bottomLeft.Normalize();
        bottomLeft *= camScale;

        // Custom Blit, encoding Frustum Corners as additional Texture Coordinates
        RenderTexture.active = destination;

        material.SetTexture("_MainTex", source);

        GL.PushMatrix();
        GL.LoadOrtho();

        material.SetPass(0);

        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.MultiTexCoord(1, bottomLeft);
        GL.Vertex3(0.0f, 0.0f, 0.0f);

        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.MultiTexCoord(1, bottomRight);
        GL.Vertex3(1.0f, 0.0f, 0.0f);

        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.MultiTexCoord(1, topRight);
        GL.Vertex3(1.0f, 1.0f, 0.0f);

        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.MultiTexCoord(1, topLeft);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }
}
