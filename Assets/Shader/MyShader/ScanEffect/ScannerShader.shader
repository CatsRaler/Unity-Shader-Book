Shader "OtherShader/ScannerShader"
{
    Properties
    {   
        _MainTex("Texture", 2D) = "white" {}
        _DetailTex("Texture", 2D) = "white" {}
        _ScanDistance("Scan Distance", float) = 0
        _ScanWidth("Scan Width", float) = 10
        _LeadSharp("Leading Edge Sharpness", float) = 10
        _LeadColor("Leading Edge Color", Color) = (1, 1, 1, 0)
        _MidColor("Mid Color", Color) = (1, 1, 1, 0)
        _TrailColor("Trail Color", Color) = (1, 1, 1, 0)
        _HBarColor("Horizontal Bar Color", Color) = (0.5, 0.5, 0.5, 0)
    }
    SubShader
    {
        Cull off
        ZWrite off
        ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 ray : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uv_depth : TEXCOORD1;
                float4 interpolatedRay : TEXCOORD2;
            };

            //float4 _MainTex_TexelSize;
            float4 _CameraWS;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.uv.xy;
                o.uv_depth = v.uv.xy;

                //注意平台适配,如果跟dx一样从上开始的话就要把后处理的uv上下颠倒一下，即1minus
                //#if UNITY_UV_STARTS_AT_TOP
                //if (_MainTex_TexelSize.y < 0)
                //    o.uv.y = 1 - o.uv.y;
                //#endif				    

                o.interpolatedRay = v.ray;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _DetailTex;
            sampler2D_float _CameraDepthTexture;
            float4 _WorldSpaceScannerPos;

            //视觉效果相关参数
            float _ScanDistance;
            float _ScanWidth;
            float _LeadSharp;
            float4 _LeadColor;
            float4 _MidColor;
            float4 _TrailColor;
            float4 _HBarColor;

            //用一个函数写横向纹理
            float4 horizBars(float2 p)
            {
                return 1 - saturate(round(abs(frac(p.y * 100) * 2)));
            }
            //用一个函数写横纵向纹理
            float4 horizTex(float2 p)
            {
                return tex2D(_DetailTex, float2(p.x * 30, p.y * 40));
            }

            float4 frag (v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv);

                float rawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv_depth));
                float linearDepth = Linear01Depth(rawDepth);

                //linearDepth存储了每个fragment对于相机的深度信息
                //i.interpolatedRay是相机射到远裁剪面的射线，乘上深度信息就是wsDir，即相机到fragment的向量
                //_WorldSpaceCameraPos是世界原点到相机的向量，加上wsDir之后就是fragment的世界坐标

                float4 wsDir = linearDepth * i.interpolatedRay;
                float3 wsPos = _WorldSpaceCameraPos + wsDir;
                float4 scannerCol = float4(0, 0, 0, 0);

                float dist = distance(wsPos, _WorldSpaceScannerPos);

                //对扫描边界线进行渲染，值得注意的是linearDepth < 1，如果不加这一条的话会一路扫描到天空盒
                if (dist < _ScanDistance && dist > _ScanDistance - _ScanWidth && linearDepth < 1)
                {
                    float diff = 1 - (_ScanDistance - dist) / (_ScanWidth);
                    half4 edge = lerp(_MidColor, _LeadColor, pow(diff, _LeadSharp));
                    scannerCol = lerp(_TrailColor, edge, diff) + horizBars(i.uv) * _HBarColor;
                    scannerCol *= diff;
  
                }

                return col + scannerCol;
            }
            ENDCG
        }
    }
}
