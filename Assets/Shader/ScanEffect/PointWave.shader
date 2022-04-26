Shader "OtherShader/ScannerShader"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _DetailTex("Texture", 2D) = "white" {}
        _ScanDistance("Scan Distance", float) = 0
        _WaveWidth("Wave Width", float) = 1
        _WaveFrequency("Wave Frequency", float) = 1
        _SpreadSpeed("Spread Speed", float) = 10
        
        _WaveColor("Wave Color", Color) = (0,0,0,1)
        _GlitchColor("Glitch Color", Color) = (0,0,0,1)
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

                float4 _MainTex_TexelSize;
                float4 _CameraWS;

                v2f vert(appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                    o.uv = v.uv.xy;
                    o.uv_depth = v.uv.xy;

                    //ע��ƽ̨����,�����dxһ�����Ͽ�ʼ�Ļ���Ҫ�Ѻ����uv���µߵ�һ�£���1minus
                    #if UNITY_UV_STARTS_AT_TOP
                    if (_MainTex_TexelSize.y < 0)
                        o.uv.y = 1 - o.uv.y;
                    #endif				    

                    o.interpolatedRay = v.ray;
                    return o;
                }

                sampler2D _MainTex;
                sampler2D _DetailTex;
                sampler2D_float _CameraDepthTexture;
                float4 _WorldSpaceScannerPos;

                //�Ӿ�Ч����ز���
                float _ScanDistance;
                float _WaveWidth;
                float _WaveFrequency;
                float _SpreadSpeed;
                float4 _WaveColor;
                float4 _GlitchColor;

                //��һ������д��������
                float4 horizBars(float2 p)
                {
                    return 1 - saturate(round(abs(frac(p.y * 1000) * 2)));
                }
                //��һ������д����������
                float4 horizTex(float2 p)
                {
                    return tex2D(_DetailTex, float2(p.x , p.y ));
                }

                float4 frag(v2f i) : SV_Target
                {
                    float4 col = tex2D(_MainTex, i.uv);
                    float rawDepth = DecodeFloatRG(tex2D(_CameraDepthTexture, i.uv_depth));
                    float linearDepth = Linear01Depth(rawDepth);

                    //linearDepth�洢��ÿ��fragment��������������Ϣ
                    //i.interpolatedRay������䵽Զ�ü�������ߣ����������Ϣ����wsDir���������fragment������
                    //_WorldSpaceCameraPos������ԭ�㵽���������������wsDir֮�����fragment����������

                    float4 wsDir = linearDepth * i.interpolatedRay;
                    float3 wsPos = _WorldSpaceCameraPos + wsDir;
                    float dist = distance(wsPos, _WorldSpaceScannerPos);

                    //col.xyz += abs(sin(_Time.y));
                    //��ɨ��߽��߽�����Ⱦ��ֵ��ע�����linearDepth < 1�����������һ���Ļ���һ·ɨ�赽��պ�
                    if (dist < _ScanDistance && dist > 1 && linearDepth < 1)
                    {

                        //����+- _Time.y��������/������ɢ
                        if ( abs(sin ((dist * (1/_WaveFrequency)) - _Time.y * _SpreadSpeed ) ) > _WaveWidth ) {
                            float4 temp = horizBars(i.uv);
                            temp *= _GlitchColor;
                            col += _WaveColor;
                            col += temp;
                        }
                    }

                    return col;
                }
                ENDCG
            }
        }
}
