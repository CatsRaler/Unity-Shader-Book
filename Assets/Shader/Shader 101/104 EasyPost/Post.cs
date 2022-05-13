using UnityEngine;

//[ExecuteInEditMode]
public class Post : MonoBehaviour
{
    public Material EffectMaterial;

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        //Debug.Log("post processing");
        if (EffectMaterial != null)
            Graphics.Blit(src, dst, EffectMaterial);
    }
}