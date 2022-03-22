
//fix function shader

Shader "UnityShaderBook/test2"{

	Properties{
		_Color("Main color",color) = (1,1,1,1)
		_Ambient("Ambient",color) = (0.3,0.3,0.3,0.3)
		_Specular("Specular",color) = (1,1,1,1)
		_Shininess("Shininess",range(0,1)) = 0
		_Emission("Emission",color) = (1,1,1,1)

		_MainTex("MainTex",2d) = "" {}
		_MainTex2("MainTex2",2d) = "" {}
		_Constant("ConstantColor",color) = (1,1,1,1)
	}

	SubShader{
		Tags{"Queue" = "Transparent"}

		Pass{
			Blend SrcAlpha OneMinusSrcAlpha

			//color[_Color]
			material{
				diffuse[_Color]
				ambient[_Ambient]
				specular[_Specular]
				shininess[_Shininess]
				emission[_Emission]
			}
			lighting on
			separatespecular on

			settexture[_MainTex]{
				combine texture * primary double
			}

			settexture[_MainTex2]{
				constantColor[_Constant]
				combine texture * previous double,texture * constant
			}

		}
	}
}