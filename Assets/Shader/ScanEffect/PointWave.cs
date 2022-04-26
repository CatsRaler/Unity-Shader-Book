using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PointWave : MonoBehaviour
{
    //扫描的起点，扫描线材质(预处理材质)，已扫描距离
    public Transform ScannerOrigin2;
    public Material EffectMaterial2;
    public float ScanDistance2;
    public float ScanSpeed2 = 50;

    private Camera mCamera2;
    private bool scanning2;
    // Update is called once per frame
    void Update()
    {
        if (scanning2)
        {
            //ScanDistance2 += Time.deltaTime * ScanSpeed2;
        }

        //按下R键重置距离
        if (Input.GetKeyDown(KeyCode.R))
        {
            scanning2 = true;
            //ScanDistance2 = 5f;
        }

        //鼠标左键单击，射线检测获得世界坐标然后设置起点
        if (Input.GetMouseButtonDown(0))
        {
            Ray ray = mCamera2.ScreenPointToRay(Input.mousePosition);
            RaycastHit hit;
            if (Physics.Raycast(ray, out hit))
            {
                scanning2 = true;
                //ScanDistance2 = 5;
                ScannerOrigin2.position = hit.point;
            }
        }
    }

    private void OnEnable()
    {
        mCamera2 = GetComponent<Camera>();
    }

    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        EffectMaterial2.SetVector("_WorldSpaceScannerPos", ScannerOrigin2.position);
        //EffectMaterial2.SetFloat("_ScanDistance", ScanDistance2);
        RaycastCornerBlit2(source, destination, EffectMaterial2);
    }

    private void RaycastCornerBlit2(RenderTexture source, RenderTexture destination, Material material)
    {
        // Compute Frustum Corners
        float camFar = mCamera2.farClipPlane;
        float camFov = mCamera2.fieldOfView;
        float camAspect = mCamera2.aspect;

        float fovWHalf = camFov * 0.5f;

        Vector3 toRight = mCamera2.transform.right * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * camAspect;
        Vector3 toTop = mCamera2.transform.up * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 topLeft = (mCamera2.transform.forward - toRight + toTop);
        float camScale = topLeft.magnitude * camFar;

        topLeft.Normalize();
        topLeft *= camScale;

        Vector3 topRight = (mCamera2.transform.forward + toRight + toTop);
        topRight.Normalize();
        topRight *= camScale;

        Vector3 bottomRight = (mCamera2.transform.forward + toRight - toTop);
        bottomRight.Normalize();
        bottomRight *= camScale;

        Vector3 bottomLeft = (mCamera2.transform.forward - toRight - toTop);
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
