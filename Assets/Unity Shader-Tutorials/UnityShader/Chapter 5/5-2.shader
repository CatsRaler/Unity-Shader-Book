// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Shader Study/Chapter 5/5-2"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float4 vert (float4 v: POSITION):SV_POSITION
            {
                return UnityObjectToClipPos(v);
            }

            fixed4 frag () : SV_Target
            {
                return fixed4(1.0,1.0,1.0,1.0);
            }
            ENDCG
        }
    }
}
