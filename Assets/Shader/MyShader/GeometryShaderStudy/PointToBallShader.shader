Shader "MyShader/PointToBallShader"
{
    Properties
    {
        _Tint("Tint", Color) = (0.5, 0.5, 0.5, 1)
        _PointSize("Point Size", Float) = 0.05
    }
        SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct pointData
            {
                float3 position;
                float4 color;
            };

            struct v2g
            {
                float4 position : SV_POSITION;
                float4 color : COLOR0;
            };

            struct g2f 
            {
                float4 position : SV_POSITION;
                float4 color : COLOR0;
            };

            float4 _Tint;
            float _PointSize;   
            StructuredBuffer<pointData> _PointDataBuffer;

            

            v2g vert (uint id : SV_VertexID)
            {
                v2g o;
                o.position = UnityObjectToClipPos(float4(_PointDataBuffer[id].position, 0));
                o.color = _PointDataBuffer[id].color;

                return o;
            }

            [maxvertexcount(36)]
            void geom(point v2g input[1], inout TriangleStream<g2f> outStream)
            {
                float4 origin = input[0].position;
                float2 extent = abs(UNITY_MATRIX_P._11_22 * _PointSize);

                g2f o;
                o.position = input[0].position;
                o.color = input[0].color;
                outStream.Append(o);


                float radius = extent.y / origin.w * _ScreenParams.y;
                //这里可以修改多边形形状
                uint slices = min((radius + 1) / 5, 6) + 2;

                if (slices == 2) extent *= 1.2;

                // Top vertex
                o.position.y = origin.y + extent.y;
                o.position.xzw = origin.xzw;
                outStream.Append(o);

                UNITY_LOOP for (uint i = 1; i < slices; i++)
                {
                    float sn, cs;
                    sincos(UNITY_PI / slices * i, sn, cs);

                    // Right side vertex
                    o.position.xy = origin.xy + extent * float2(sn, cs);
                    outStream.Append(o);

                    // Left side vertex
                    o.position.x = origin.x - extent.x * sn;
                    outStream.Append(o);
                }

                // Bottom vertex
                o.position.x = origin.x;
                o.position.y = origin.y - extent.y;
                outStream.Append(o);

                outStream.RestartStrip();

            }

            fixed4 frag(g2f i) : SV_Target
            {
                i.color = _Tint;
                return i.color;
            }

            ENDCG
        }
    }
}
