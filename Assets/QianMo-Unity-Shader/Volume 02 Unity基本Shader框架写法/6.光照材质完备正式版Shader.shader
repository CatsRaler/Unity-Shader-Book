﻿

Shader "浅墨Shader编程/6.光照材质完备正式版Shader" 
{
	//-------------------------------【属性】-----------------------------------------
    Properties 
	{
        _Color ("主颜色", Color) = (1,1,1,0)
        _SpecColor ("高光颜色", Color) = (1,1,1,1)
        _Emission ("自发光颜色", Color) = (0,0,0,0)
        _Shininess ("光泽度", Range (0.01, 1)) = 0.7
        _MainTex ("基本纹理", 2D) = "white" {}
    }

	//--------------------------------【子着色器】--------------------------------
    SubShader
	{
		//----------------通道---------------
        Pass
		{
			//-----------材质------------
            Material
			{
				//可调节的漫反射光和环境光反射颜色
                Diffuse [_Color]
                Ambient [_Color]
				//光泽度
                Shininess [_Shininess]
				//高光颜色
                Specular [_SpecColor]
				//自发光颜色
                Emission [_Emission]
            }
			//开启光照
            Lighting On
			//开启独立镜面反射
            SeparateSpecular On
			//设置纹理并进行纹理混合
            SetTexture [_MainTex] 
			{
                Combine texture * primary DOUBLE/*, texture * primary*/
            }
        }
    }
} 