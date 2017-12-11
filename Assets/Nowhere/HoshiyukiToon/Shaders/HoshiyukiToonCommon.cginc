/** 共通関数ヘッダ.
 *
 * @date	2017/12/7
 */
#ifndef NWH_TOONCOMMON_INC
#define NWH_TOONCOMMON_INC

/* includes */
#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"

/* --- Macros --- */
	/** 直接光の強さ.
	 * 初期値は1/π
	 */
#	define NWH_TOON_FWDLIGHT_INTENSITY 0.318309
/* end */



/* --- functions --- */

#if UNITY_LIGHT_PROBE_PROXY_VOLUME
	/** ProxyVolume版トゥーンシェード向け、L0L1球面調和関数.
	 *
	 */
	half3 SHEvalLinearL0L1_SampleProbeVolume_Toon(float3 worldPos )
	{
		const float transformToLocal = unity_ProbeVolumeParams.y;
		const float texelSizeX = unity_ProbeVolumeParams.z;

		float3 position = (transformToLocal == 1.0f) ? mul( unity_ProbeVolumeWorldToObject, float4(worldPos, 1.0) ).xyz : worldPos;
		float3 texCoord = (position - unity_ProbeVolumeMin.xyz) * unity_ProbeVolumeSizeInv.xyz;
		texCoord.x = texCoord.x * 0.25f;

		float texCoordX = clamp( texCoord.x, 0.5f * texelSizeX, 0.25f - 0.5f * texelSizeX );

		texCoord.x = texCoordX;
		half4 SHAr = UNITY_SAMPLE_TEX3D_SAMPLER( unity_ProbeVolumeSH, unity_ProbeVolumeSH, texCoord );

		texCoord.x = texCoordX + 0.25f;
		half4 SHAg = UNITY_SAMPLE_TEX3D_SAMPLER( unity_ProbeVolumeSH, unity_ProbeVolumeSH, texCoord );

		texCoord.x = texCoordX + 0.5f;
		half4 SHAb = UNITY_SAMPLE_TEX3D_SAMPLER( unity_ProbeVolumeSH, unity_ProbeVolumeSH, texCoord );

		half3 x1;
		x1.r = dot( SHAr, half4(SHAr.xyz,1) );
		x1.g = dot( SHAg, half4(SHAg.xyz,1) );
		x1.b = dot( SHAb, half4(SHAb.xyz,1) );

		return x1;
	}
#endif

	/** トゥーンシェード向け、L0L1球面調和関数.
	 *
	 */
	inline half3 SHEvalLinearL0L1_Toon() {
		half3 shl;
		shl.r = dot( unity_SHAr, half4(unity_SHAr.xyz, 1.0) );
		shl.g = dot( unity_SHAg, half4(unity_SHAg.xyz, 1.0) );
		shl.b = dot( unity_SHAb, half4(unity_SHAb.xyz, 1.0) );
		return shl;
	}

	/** お手軽版、球面調和関数.
	 *
	 */
	inline half3 ShadeSHSimple() {
		
		half3 shl = SHEvalLinearL0L1_Toon();

		#ifdef UNITY_COLORSPACE_GAMMA
			shl = LinearToGammaSpace( shl );
		#endif
		return shl;
	}

	/** 頂点シェーダー版、トゥーンシェーダ向け球面調和取得関数.
	 * 使われた形跡のない幻の関数.
	 *
	 * @see UnityStandardUtils.cginc
	 */
	half3 ShadeToonSHPerVertex( half3 normal, half3 ambient ) {

		#if UNITY_SAMPLE_FULL_SH_PER_PIXEL
				// nop
		#elif (SHADER_TARGET<30) || UNITY_STANDARD_SIMPLE

			ambient += SHEvalLinearL0L1_Toon();
		#else
			#ifdef UNITY_COLORSPACE_GAMMA
				ambient = GammaToLinnerSpace( ambient );
			#endif
				ambient += SHEvalLinearL2( half4(normal, 1) );
		#endif

		return ambient;
	}

	/** ピクセルシェーダー版、トゥーンシェーダ向け球面調和取得関数.
	 *
	 * @see UnityStandardUtils.cginc
	 */
	half3 ShadeToonSHPerPixel( half3 normal, half3 ambient, float3 worldPos ) {

		half3 contrib = 0;
		half4 N = half4(normal, 1);

		#if UNITY_SAMPLE_FULL_SH_PER_PIXEL
			ambient = max( half3(0,0,0), SHEvalLinearL0L1_Toon());
		#elif (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
			// nop
		#else
			#if UNITY_LIGHT_PROBE_PROXY_VOLUME
				if (unity_ProbeVolumeParams.x == 1)
				{
					contrib = SHEvalLinearL0L1_SampleProbeVolume_Toon( worldPos );
				}
				else
				{
					contrib = SHEvalLinearL0L1_Toon();
				}
			#else
				contrib = SHEvalLinearL0L1_Toon();
			#endif
			ambient = max( half3(0, 0, 0), ambient + contrib );

			#if UNITY_COLORSPACE_GAMMA
				ambient = LinearToGammaSpace( ambient );
			#endif
		#endif

		return ambient;
	}


	/** トゥーンシェード版GI関数
	 *
	 */
	inline UnityGI ToonGI_Base( UnityGIInput data, half occlusion, half3 normalWorld ) {

		UnityGI	o_gi;
		ResetUnityGI( o_gi );

		#if !defined(LIGHTMAP_ON)
			o_gi.light			= data.light;
			o_gi.light.color	*= data.atten;
		#endif

		/* Realtime GI for dynamic objects */
		#if UNITY_SHOULD_SAMPLE_SH
			o_gi.indirect.diffuse	= ShadeToonSHPerPixel( normalWorld, half3(0, 0, 0), data.worldPos );
		#endif


		/* Baked Light map */
		#ifdef LIGHTMAP_ON
			fixed4	bakedColorTex	= UNITY_SAMPLE_TEX2D( unity_Lightmap, data.lightmap, data.lightmapUV.xy );
			half3	bakedColor		= DecodeLightmap( bakedColorTex );

			#ifdef DIRLIGHTMAP_COMBINED
				fixed4 bakedDirTex		= UNITY_SAMPLE_TEX2D_SAMPLER( unity_LightmapInd, unity_Lightmap, data.lightmapUV.xy );
				o_gi.indirect.diffuse	= DecodeDirectionalLightmap( bakedColor, bakedDirTex, normalWorld );

				#ifdef SHADOWS_SCREEN
					o_gi.indirect.diffuse = MixLightmapWithRealtimeAttenuation( o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld );
				#endif
			#elif DIRLIGHTMAP_SEPARATE

				// Direct
				fixed4 bakedDirTex		= UNITY_SAMPLE_TEX2D_SAMPLER( unity_LightmapInd, unity_Lightmap, data.lightmapUV.xy );
				o_gi.indirect.diffuse	= DecodeDirectionalSpecularLightmap( bakedColor, bakedDirTex, normalWorld, false, 0, o_gi.light );

				// Indirect
				float2 uvIndirect		= data.lightmapUV.xy + float2(0.5, 0);
				bakedColor				= DecodeLightmap( UNITY_SAMPLE_TEX2D( unity_Lightmap, uvIndirect ) );
				bakedDirTex				= UNITY_SAMPLE_TEX2D_SAMPLER( unity_LightmapInd, unity_Lightmap, uvIndirect );
				o_gi.indirect.diffuse	+= DecodeDirectionalSpecularLightmap( bakedColor, bakedDirTex, normalWorld, false, 0, o_gi.light2 );

				#ifdef SHADOWS_SCREEN
					o_gi.light.color		= MixLightmapWithRealtimeAttenuation( o_gi.light.color, data.atten, bakedColorTex, normalWorld );
					o_gi.light2.color		= MixLightmapWithRealtimeAttenuation( o_gi.light2.color, data.atten, bakedColorTex, normalWorld );
					o_gi.indirect.diffuse	= MixLightmapWithRealtimeAttenuation( o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld );
				#endif
			#else // Not directional lightmap

				o_gi.indirect.diffuse	= bakedColor;
				#ifdef SHADOWS_SCREEN
					o_gi.indirect.diffuse	= MixLightmapWithRealtimeAttenuation( o_gi.indirect.diffuse, data.atten, bakedColorTex, normalWorld );
				#endif
			#endif
		#endif


		/* Realtime GI for static */
		#ifdef DYNAMICLIGHTMAP_ON
			fixed4	realtimeColorTex	= UNITY_SAMPLE_TEX2D( unity_DynamicLightmap, data.lightmapUV.zw );
			half3	realtimeColor		= DecodeRealtimeLightmap( realtimeColorTex );

			#ifdef DIRLIGHTMAP_COMBINED
				half4 realtimeDirTex	= UNITY_SAMPLE_TEX2D_SAMPLER( unity_DynamicDirectionality, unity_DynamicLightmap, data.lightmapUV.zw );
				o_gi.indirect.diffuse	+= DecodeDirectionalLightmap( realtimeColor, realtimeDirTex, normalWorld );

			#elif DIRLIGHTMAP_SEPARATE
				half4 realtimeDirTex	= UNITY_SAMPLE_TEX2D_SAMPLER( unity_DynamicDirectionality, unity_DynamicLightmap, data.lightmapUV.zw );
				half4 realtimeNormalTex	= UNITY_SAMPLE_TEX2D_SAMPLER( unity_DynamicNormal, unity_DynamicLightmap, data.lightmapUV.zw );
				o_gi.indirect.diffuse	+= DecodeDirectionalSpecularLightmap( realtimeColor, realtimeDirTex, normalWorld, true, realtimeNormalTex, o_gi.light3 );

			#else
				o_gi.indirect.diffuse	+= realtimeColor;
			#endif
		#endif

		o_gi.indirect.diffuse	*= occlusion;
		return o_gi;
	}
/* end */
#endif