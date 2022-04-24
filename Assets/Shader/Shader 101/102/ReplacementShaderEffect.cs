using UnityEngine;
using System.Collections;
using System.Collections.Generic;

[ExecuteInEditMode]
public class ReplacementShaderEffect : MonoBehaviour
{
    public Color ScanLineColor;
    public float ScanLineWidth;
    public float ScanLineSpeed;
    public Shader ReplacementShader;

    void OnValidate()
    {
        //Shader.SetGlobalColor("_LineColor", color);
        Shader.SetGlobalColor("_LineColor", ScanLineColor);
        Shader.SetGlobalFloat("_ScanLineWidth", ScanLineWidth);
        Shader.SetGlobalFloat("_ScanLineSpeed", ScanLineSpeed);
    }

    private void Update()
    {
        
    }

    void OnEnable()
    {  
        if (ReplacementShader != null)
            GetComponent<Camera>().SetReplacementShader(ReplacementShader, "");
    }

    void OnDisable()
    {
        GetComponent<Camera>().ResetReplacementShader();
    }

}