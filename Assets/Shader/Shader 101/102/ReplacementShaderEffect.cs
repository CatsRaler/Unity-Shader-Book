using UnityEngine;
using System.Collections;
using System.Collections.Generic;

[ExecuteInEditMode]
public class ReplacementShaderEffect : MonoBehaviour
{
    public Color color;
    public float slider;
    public Shader ReplacementShader;

    void OnValidate()
    {
        //Shader.SetGlobalColor("_LineColor", color);
        Shader.SetGlobalColor("_LineColor", color);
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