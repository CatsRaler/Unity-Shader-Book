Shader "Shader101/106-2 RedSilhouette"
{
	Properties
	{
		_EdgeColor("Edge Color", Color) = (1,1,1,1)
	}

	SubShader
	{
		/*Stencil
		{
			Ref 1
			Comp LEqual
		}*/

		Tags
		{
			"Queue" = "Transparent"
			"RenderType" = "Transparent"
			"XRay" = "RedSilhouette"
		}

		ZWrite Off
		ZTest Always
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{	
			Stencil
			{
				Ref 1
				Comp LEqual
			}

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
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			float4 _EdgeColor;
			fixed4 frag (v2f i) : SV_Target
			{
				return _EdgeColor;
			}

			ENDCG
		}
	}
	Fallback "Legacy Shaders/VertexLit"
}
