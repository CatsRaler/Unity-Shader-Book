// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Shader Study/Chapter 6/6-4-3"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
    }
    SubShader
    {
        Pass
        {   
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Lighting.cginc"

            fixed4 _Diffuse;

            struct a2v{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                };

            struct v2f{
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXTCOORD0;
                };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

                return o;
                }
            //逐像素光照会导致光照不到的位置偏黑，可以使用半兰伯特光照模型
            fixed4 frag(v2f i) : SV_Target{
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed halfLamert = dot(worldNormal,worldLightDir) * 0.5 + 0.5;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLamert;
                fixed3 color = ambient + diffuse;
                return fixed4(color, 1.0);

                }

            ENDCG
        }
    }
    //Fallback "Diffuse"
}
