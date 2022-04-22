Shader "Shader101/103-3 Rim+Toon Shader"
{
	Properties
	{
		_MainTex("Base texture", 2D) = "white" {}
		_RampTex("Ramp texture", 2D) = "white" {}

		_AmbientStrength("Ambient Strength",Range(0,1.0)) = 0.1
		_DiffStrength("Diff Strength",Range(0,1.0)) = 0.1
		_SpecStrength("Spec Strength",Range(0,5.0)) = 0.1
		_RimStrength("Rim Strength",Range(0,1.0)) = 0.1
		_RimAmount("Rim Amount",Range(0,1.0)) = 0.1

		_SpecPow("Specular Pow",int) = 0.5
		_Brightness("Brightness",Range(0,1.0)) = 0.5
		_TintColor("Tint Color",Color) = (1.0,1.0,1.0,1.0)
		_OutlineAmount("Outline Amout",Range(0,1.0)) = 0.5
		_OutlineColor("Outline Color",Color) = (1.0,1.0,1.0,1.0)
	}

		SubShader
		{
			Tags
			{
				"LightMode" = "ForwardBase"
				"PassFlags" = "OnlyDirectional"
			}
			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#include "UnityLightingCommon.cginc" // for _LightColor0
				#include "UnityCG.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float2 uv: TEXCOORD0;
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					float3 normal : NORMAL;
					float2 uv: TEXCOORD0;
					float3 viewDir : TEXCOORD1;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.uv = v.uv;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.normal = UnityObjectToWorldNormal(v.normal);
					o.viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
					return o;
				}

				sampler2D _MainTex;
				sampler2D _RampTex;

				float _AmbientStrength;
				float _SpecStrength;
				float _DiffStrength;
				float _RimStrength;
				float _RimAmount;

				float4 _TintColor;
				float4 _RimColor;
				float _SpecPow;
				float _Brightness;
				float _OutlineAmount;
				float4 _OutlineColor;

				float4 frag(v2f i) : SV_Target
				{
					float4 baseColor = tex2D(_MainTex, i.uv);
					float3 normal = normalize(i.normal);
					//ambient
					float3 ambient = _LightColor0 * _AmbientStrength;

					//diffuse
					float NdotL = dot(i.normal, _WorldSpaceLightPos0);
					float2 uv = float2((NdotL * 0.5 + 0.5), 0);
					float3 ramp = tex2D(_RampTex, uv);

					// 把(NdotL < 0) ? 0 : 1 改成ramp 如果需要用自己的texture
					//float3 diff = (NdotL < 0) ? 0 : 1 * _LightColor0 * _DiffStrength;
					float3 diff = ramp * _LightColor0 * _DiffStrength;

					//specular
					float3 reflectDir = reflect(-_WorldSpaceLightPos0, normal);
					float spec = pow(max(dot(i.viewDir, reflectDir), 0.0), _SpecPow);
					float3 specSmooth = smoothstep(0.005, 0.01, spec) * _LightColor0 * _SpecStrength;

					//rimlight
					float NdotV = 1 - dot(i.normal, i.viewDir);
					float rimSmooth = max(0,NdotL) * smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, NdotV);
					float3 rimlight = rimSmooth * _LightColor0 * _RimStrength;

					//根据NdotV来渲染外围线
					float4 final_color;
					//小于阈值就进行正常的PhongShading，大于等于阈值就改为纯色，可以成为基于模型的边缘着色
					//这跟无主之地的不一样，因为这个方法是基于NdotV进行计算渲染的，然后模型不同边缘位置法线不一样，所以边缘轮廓
					//渲染出来是不清晰的，无主之地使用的类似后处理效果，使用Sobel算子进行边缘检测，把模型边缘部分着色，但是非边缘
					//部分也有一些边缘着色效果，应该是用本代码类似方法或者换了个算子算出来的
					if (NdotV < _OutlineAmount) {
						final_color = float4((diff + ambient + specSmooth + rimlight), 1.0) * _Brightness * baseColor * _TintColor;
					}
					else {
						final_color = _OutlineColor;
					}

					//final color
					//float4 final_color = float4((diff + ambient + specSmooth + rimlight),1.0) * _Brightness * baseColor * _TintColor;

					return final_color;
				}
				ENDCG
			}
		}
}
