using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PointToBall : MonoBehaviour
{
    public Material material;
    ComputeBuffer mPointDataBuffer;
    int mPointCount;

    public Transform testPoint;
    //public Color testColor;

    struct PointData {
        public Vector3 position;
        public Color color;
    }

    // Start is called before the first frame update
    void Start()
    {
        mPointCount = 1;
        PointData[] pointDatas = new PointData[mPointCount];
        for(int i = 0 ; i < pointDatas.Length; i++)
        {
            pointDatas[i].position = testPoint.position;
            //pointDatas[i].color = testColor;
        }
        mPointDataBuffer = new ComputeBuffer(mPointCount, 10);
        mPointDataBuffer.SetData(pointDatas);
    }

    // Update is called once per frame
    void Update()
    {
        material.SetBuffer("_PointDataBuffer", mPointDataBuffer);
    }
    void OnRenderObject()
    {
        material.SetPass(0);
        Graphics.DrawProceduralNow(MeshTopology.Points, mPointCount);
    }
}
