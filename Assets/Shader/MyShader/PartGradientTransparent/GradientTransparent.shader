Shader "MyShader/GradientTransparent"
{
	Properties{
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex("Main Tex", 2D) = "white" {}
		_AlphaScale("Alpha Scale", Range(0, 1)) = 1
		_StartHeight("StartHeight" , float) = 5
		_EndHeight("EndHeight" , float) = 10
	}
		SubShader{
			Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}

			Pass {
				Tags { "LightMode" = "ForwardBase" }

				// First pass renders only back faces 
				Cull Front

				ZWrite Off
				Blend SrcAlpha OneMinusSrcAlpha

				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"

				fixed4 _Color;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				fixed _AlphaScale;

				float _StartHeight;
				float _EndHeight;

				struct a2v {
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float4 texcoord : TEXCOORD0;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float3 worldNormal : TEXCOORD0;
					float3 worldPos : TEXCOORD1;
					float2 uv : TEXCOORD2;
				};

				v2f vert(a2v v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);

					o.worldNormal = UnityObjectToWorldNormal(v.normal);

					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

					return o;
				}

				fixed4 frag(v2f i) : SV_Target {
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

					fixed4 texColor = tex2D(_MainTex, i.uv);

					fixed3 albedo = texColor.rgb * _Color.rgb;

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

					fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

					if (i.worldPos.y > _StartHeight && i.worldPos.y < _EndHeight)
					{
						float temp = (_EndHeight - i.worldPos.y) / (_EndHeight - _StartHeight);
						return fixed4(ambient + diffuse, texColor.a * temp);
					}
					else if (i.worldPos.y >= _EndHeight)
					{
						return fixed4(ambient + diffuse, texColor.a * 0);
					}

					return fixed4(ambient + diffuse, texColor.a * 1);
				}

				ENDCG
			}

			Pass {
				Tags { "LightMode" = "ForwardBase" }

				// Second pass renders only front faces 
				Cull Back

				ZWrite Off
				Blend SrcAlpha OneMinusSrcAlpha

				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"

				fixed4 _Color;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				fixed _AlphaScale;

				float _StartHeight;
				float _EndHeight;

				struct a2v {
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float4 texcoord : TEXCOORD0;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float3 worldNormal : TEXCOORD0;
					float3 worldPos : TEXCOORD1;
					float2 uv : TEXCOORD2;
				};

				v2f vert(a2v v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);

					o.worldNormal = UnityObjectToWorldNormal(v.normal);

					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

					return o;
				}

				fixed4 frag(v2f i) : SV_Target {
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

					fixed4 texColor = tex2D(_MainTex, i.uv);

					fixed3 albedo = texColor.rgb * _Color.rgb;

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

					fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

					if (i.worldPos.y > _StartHeight && i.worldPos.y < _EndHeight)
					{
						float temp = (_EndHeight - i.worldPos.y) / (_EndHeight - _StartHeight);
						return fixed4(ambient + diffuse, texColor.a * temp);
					}
					else if (i.worldPos.y >= _EndHeight)
					{
						return fixed4(ambient + diffuse, texColor.a * 0);
					}

					return fixed4(ambient + diffuse, texColor.a * 1);
				}

				ENDCG
			}
		}
			FallBack "Transparent/Cutout/VertexLit"
}
