Shader "Toon/Lit" {
	Properties{
		_Color("Main Color", Color) = (0.5,0.5,0.5,1)
		_MainTex("Base (RGB)", 2D) = "white" {}
		_Ramp("Toon Ramp (RGB)", 2D) = "white" {}
	}

		SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 200

			CGPROGRAM
			#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows exclude_path:deferred BlendOp Max

			uniform float4 _Color;
			uniform sampler2D _MainTex;
			uniform sampler2D _Ramp;

			#include "UnityPBSLighting.cginc"
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#include "Lighting.cginc"

			#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
			#endif

			struct Input
			{
				float2 uv_MainTex;
				float3 worldNormal;
				INTERNAL_DATA
				float3 worldPos;
			};

			struct SurfaceOutputCustomLightingCustom
			{
				half3 Albedo;
				half3 Normal;
				half3 Emission;
				half Metallic;
				half Smoothness;
				half Occlusion;
				half Alpha;
				Input SurfInput;
				UnityGIInput GIData;
			};


			inline half4 LightingStandardCustomLighting(inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi)
			{
				UnityGIInput data = s.GIData;
				Input i = s.SurfInput;
				half4 c = 0;

	#ifdef UNITY_PASS_FORWARDBASE
				float lightAtten = data.atten;
				if (_LightColor0.a == 0)
					lightAtten = 0;
	#else
				float3 ase_lightAttenRGB = gi.light.color / ((_LightColor0.rgb) + 0.000001);
				float lightAtten = max(max(ase_lightAttenRGB.r, ase_lightAttenRGB.g), ase_lightAttenRGB.b);
	#endif

				float3 worldLightDir = Unity_SafeNormalize(UnityWorldSpaceLightDir(i.worldPos));
				float3 worldNormal = normalize(WorldNormalVector(i, float3(0, 0, 1)));
				float wrapInput = (dot(worldNormal, worldLightDir) *0.5) + 0.5;
				float2 wrapInputVector = (float2(wrapInput, wrapInput));

				lightAtten = (2.0 * lightAtten);
				float4 lightColor = _LightColor0;
				float4 directLighting = saturate(lightColor * lightAtten);

				UnityGI gi32 = gi;
				float3 diffNorm32 = worldNormal;
				gi32 = UnityGI_Base(data, 1, diffNorm32);
				float3 indirectDiffuse32 = gi32.indirect.diffuse + diffNorm32 * 0.0001;

				float4 lighting = ((tex2D(_Ramp, wrapInputVector) * directLighting) + float4(indirectDiffuse32, 0.0));
				c.rgb = (_Color * tex2D(_MainTex, i.uv_MainTex)) * lighting;
				c.a = 1;

				return c;
			}

			inline void LightingStandardCustomLighting_GI(inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi)
			{
				s.GIData = data;
			}

			void surf(Input i, inout SurfaceOutputCustomLightingCustom o)
			{
				o.SurfInput = i;
			}

			ENDCG
	}
		Fallback "Diffuse"
}
