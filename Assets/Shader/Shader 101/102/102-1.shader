Shader "Shader101/102-1 DepthPic"
{

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        ZWrite On

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                //float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                //float2 uv : TEXCOORD0;
                //UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float depth : DEPTH;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.depth = -(mul(UNITY_MATRIX_MV, v.vertex).z) * _ProjectionParams.w;
                return o;
            }

            //把深度展现出来
            fixed4 frag(v2f i) : SV_Target
            {
                float invert = 1 - i.depth;
            return fixed4(invert, invert, invert, 1);
            }
            ENDCG
        }
    }
}
