Shader "Shader101/102-2 Scan"
{	


	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque"
		}

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
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float depth : DEPTH;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.depth = -(mul(UNITY_MATRIX_MV, v.vertex).z) * _ProjectionParams.w;
				return o;
			}

			//��Ϊƫ���ں�������shader�еĲ���Ҫ�ڽű������޸�
			float4 _LineColor;
			float _Temp;

			fixed4 frag(v2f i) : SV_Target
			{
				float invert = 1 - i.depth;

				//��������tan���������㲨�������Ļ��Ϳ��԰���һ��ʱ��ƬBiubiubiu
				_Temp = tan(_Time.y * 1.2);
				if (abs(i.depth - _Temp / 2) < 0.01)
					return fixed4(_LineColor.x, _LineColor.y, _LineColor.z, 1);
				else
					return fixed4(invert, invert, invert,1);
			}
			ENDCG
		}
	}
}
