Shader "MyShader/ScreenGradientSampleShader"
{
	Properties
	{
		_MainTex("MainTex", 2D) = "white"{}

		_ChangeProportion0("_ChangeProportion0" , float) = 0.5
		_ChangeProportion1("_ChangeProportion1" , float) = 0.5
		_ChangeProportion2("_ChangeProportion2" , float) = 0.5
		_ChangeProportion3("_ChangeProportion3" , float) = 0.5
		_ChangeProportion4("_ChangeProportion4" , float) = 0.5

		_Hatch0("Hatch 0", 2D) = "white" {}
		_Hatch1("Hatch 1", 2D) = "white" {}
		_Hatch2("Hatch 2", 2D) = "white" {}
		_Hatch3("Hatch 3", 2D) = "white" {}
		_Hatch4("Hatch 4", 2D) = "white" {}
	}

		SubShader
	{
		//透明队列
		Tags {"Queue" = "Transparent" "RenderType" = "Transparent" }
		//常规透明混合
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite Off
		Offset[_OffsetFactor],[_OffsetUnits]

		Pass
		{

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _ChangeProportion0;
			float _ChangeProportion1;
			float _ChangeProportion2;
			float _ChangeProportion3;
			float _ChangeProportion4;

			sampler2D _Hatch0;
			sampler2D _Hatch1;
			sampler2D _Hatch2;
			sampler2D _Hatch3;
			sampler2D _Hatch4;


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v) {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}

			float4 frag(v2f i) : SV_Target {
				float4 col = tex2D(_MainTex, i.uv);


				float rate = i.vertex.y / _ScreenParams.y;
				//col *= lerp(_Color1, _Color2, rate);
				if (rate <= _ChangeProportion0) {
					col *= tex2D(_Hatch0, i.uv);
				}
				else if (rate > _ChangeProportion0 && rate <= _ChangeProportion1) {
					col *= tex2D(_Hatch1, i.uv);
				}
				else if (rate > _ChangeProportion1 && rate <= _ChangeProportion2) {
					col *= tex2D(_Hatch2, i.uv);
				}
				else if (rate > _ChangeProportion2 && rate <= _ChangeProportion3) {
					col *= tex2D(_Hatch3, i.uv);
				}
				else if (rate > _ChangeProportion3 && rate <= _ChangeProportion4) {
					col *= tex2D(_Hatch4, i.uv);
				}
				else if (rate > _ChangeProportion4) {
					col.a = 0;
				}
				else {
					col.a = 1;
				}


				UNITY_APPLY_FOG(i.fogCoord, col);
				//col.a = 0.8;
				return col;

			}
		 ENDCG
	 }
	}

		//FallBack "Diffuse"
}
