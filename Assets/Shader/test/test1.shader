
//my first shader

Shader "UnityShaderBook/test1"{

	Properties{
		_Color("Main color",color) = (1,1,1,1)
		_Ambient("Ambient",color) = (0.3,0.3,0.3,0.3)
		_Specular("Specular",color) = (1,1,1,1)
		_Shininess("Shininess",range(0,0.1)) = 0
		_Emission("Emission",color) = (1,1,1,1)
	}

	SubShader{
		Pass{
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
		}
	}
}