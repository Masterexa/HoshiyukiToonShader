using System.Collections;
using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;


namespace NowhereUnityEditor.Rendering{

	///<summary>シェーダーのカスタムエディタ</summary>
	///<remarks>
	///
	///</remarks>
	public class HoshiyukiToonEditor : ShaderGUI{

        #region Typedefs
            enum BlendMode {
                Opaque,
                Cutoff
            }

            [System.Flags]
            enum EditFlag {
                None,
                Lit = 0x1,
                Line = 0x2,
                ModeEditable = 0x4,
            }

            [System.Serializable]
            class Styles {
                public GUIContent renderingMode  = new GUIContent("Rendering Mode", "Rendering Mode");
                public GUIContent albedoText     = new GUIContent("Albedo", "Albedo(RGB) and Transparency(Alpha)");
                public GUIContent alphaCutoffText= new GUIContent("Alpha Cutoff", "");
                public GUIContent rampText       = new GUIContent("Ramp", "");

                public GUIContent occlusionText  = new GUIContent("Occlusion", "");
                public GUIContent emissionText   = new GUIContent("Emission", "");

                public GUIContent lineSizeText   = new GUIContent("Size", "Size of Outline(Viewport Space)");
                public GUIContent lineColorText  = new GUIContent("Color", "Color(RGB) and Transparency(Alpha)");

                public GUIContent standardGIText = new GUIContent("Use Traditional GI", "");
                public GUIContent cullModeText   = new GUIContent("Cull Mode", "");

                public string tipsText                  = "Recommend \"No ramp\" and \"No shadow casting\" for character material.";
                public string primaryMapsText           = "Main Maps";
                public string lineSettingsText          = "Outline";
                public string advancedOptionsText       = "Advanced Options";
                public readonly string[] blendNames     = Enum.GetNames(typeof(BlendMode));
            }
            static Styles   s_styles;

        #endregion

        #region Instance
            #region Fields
                MaterialProperty    blendMode;
                MaterialProperty    albedoColor;
                MaterialProperty    albedoMap;
                MaterialProperty    alphaCutoff;
                MaterialProperty    rampMap;
                MaterialProperty    rampPointMap;
                MaterialProperty    rampFactor;
                MaterialProperty    occlusionFactor;
                MaterialProperty    occlusionMap;
                MaterialProperty    emissionColor;
                MaterialProperty    emissionMap;

                MaterialProperty    lineColor;
                MaterialProperty    lineSize;
                MaterialProperty    lineCull;
                
                MaterialProperty    cullMode;
                MaterialProperty    useStandardGI;

                bool                    m_firstTimeApply    = true;
                MaterialEditor          m_materialEditor    = null;
                EditFlag                m_editFlag          = EditFlag.None;
                ColorPickerHDRConfig    m_hdrPickerConfig   = new ColorPickerHDRConfig(0f, 99f, 1f/99f, 3f);
            #endregion

            #region Properties
            #endregion

            #region GUI Methods
                public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props) {
            
                    if( s_styles==null )
                    {
                        s_styles = new Styles();
                        TryLocalize();
                    }

                    FindProperties(props);
                    m_materialEditor    = materialEditor;
                    var mtl             = materialEditor.target as Material;

                    if( m_firstTimeApply )
                    {
                        MaterialChanged(mtl);
                        m_firstTimeApply = false;
                    }
                    ShaderPropertiesGUI(mtl);
                }

                void ShaderPropertiesGUI(Material mtl) {

                    EditorGUIUtility.labelWidth = 0f;
                    
                    EditorGUI.BeginChangeCheck();
                    {
                        //EditorGUILayout.HelpBox(s_styles.tipsText, MessageType.Info);

                        // Menus
                        DoRenderingSettingsArea(mtl);
                        DoBaseMapArea(mtl);
                        DoLineArea(mtl);
                        DoOptionsArea(mtl);
                    }
                    if( EditorGUI.EndChangeCheck() )
                    {
                        foreach(var it in albedoColor.targets)
                            MaterialChanged((Material)it);
                    }
                }


                void DoRenderingSettingsArea(Material mtl){
                    BlendModeProp();
                    m_materialEditor.ShaderProperty(cullMode, s_styles.cullModeText);
                }

                void DoBaseMapArea(Material mtl) {
                    GUILayout.Label(s_styles.primaryMapsText, EditorStyles.boldLabel);
                    DoAlbedoArea(mtl);
                    DoRampArea(mtl);
                    m_materialEditor.TexturePropertySingleLine(s_styles.occlusionText, occlusionMap, (occlusionMap.textureValue!=null) ? occlusionFactor : null);
                    DoEmissionArea(mtl);
                    m_materialEditor.TextureScaleOffsetProperty(albedoMap);
                }

                void DoRampArea(Material mtl) {
            
                    m_materialEditor.ShaderProperty(rampFactor, s_styles.rampText);
                    EditorGUI.indentLevel++;
                    {
                        m_materialEditor.TexturePropertySingleLine(new GUIContent("Directional Light"), rampMap);
                        m_materialEditor.TexturePropertySingleLine(new GUIContent("Point Light"), rampPointMap);
                    }
                    EditorGUI.indentLevel--;
                }

                void DoLineArea(Material mtl) {
                    if( (m_editFlag&EditFlag.Line)!=0 )
                    {
                        EditorGUILayout.Space();
                        GUILayout.Label(s_styles.lineSettingsText, EditorStyles.boldLabel);

                        m_materialEditor.ShaderProperty(lineColor, s_styles.lineColorText);
                        m_materialEditor.ShaderProperty(lineSize, s_styles.lineSizeText);
                        if( lineCull!=null )
                        {
                            m_materialEditor.ShaderProperty(lineCull, s_styles.cullModeText);
                        }
                    }
                }

                void DoOptionsArea(Material mtl) {
                    EditorGUILayout.Space();
                    GUILayout.Label(s_styles.advancedOptionsText, EditorStyles.boldLabel);
                    m_materialEditor.ShaderProperty(useStandardGI, s_styles.standardGIText);
                }


                void BlendModeProp() {
                    if( (m_editFlag&EditFlag.ModeEditable)==0 )
                    {
                        return;
                    }

                    EditorGUI.showMixedValue = blendMode.hasMixedValue;
                    var mode = (BlendMode)blendMode.floatValue;

                    EditorGUI.BeginChangeCheck();
                    {
                        mode = (BlendMode)EditorGUILayout.Popup(s_styles.renderingMode.text, (int)mode, s_styles.blendNames);
                    }
                    if( EditorGUI.EndChangeCheck() )
                    {
                        m_materialEditor.RegisterPropertyChangeUndo("Rendering mode");
                        blendMode.floatValue = (float)mode;
                    }

                    EditorGUI.showMixedValue = false;
                }

                void DoAlbedoArea(Material mtl) {

                    m_materialEditor.TexturePropertySingleLine(s_styles.albedoText, albedoMap, albedoColor);
                    if( ((m_editFlag&EditFlag.ModeEditable)!=0) && (BlendMode)mtl.GetFloat("_Blend")==BlendMode.Cutoff )
                    {
                        m_materialEditor.ShaderProperty(alphaCutoff, s_styles.alphaCutoffText, MaterialEditor.kMiniTextureFieldLabelIndentLevel+1);
                    }
                }

                void DoEmissionArea(Material mtl) {

                    bool showHelp       = !HasValidEmissiveKeyword(mtl);
                    bool hadEmissionTex = emissionMap.textureValue != null;

                    // Texture and HDR color controls
                    m_materialEditor.TexturePropertyWithHDRColor(s_styles.emissionText, emissionMap, emissionColor, m_hdrPickerConfig, false);
                    
                    float brightness = emissionColor.colorValue.maxColorComponent;
                    if( emissionMap.textureValue!=null && !hadEmissionTex && (brightness<=0) )
                    {
                        emissionColor.colorValue = Color.white;
                    }

                    // Emission for GI ?
                    m_materialEditor.LightmapEmissionProperty(MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);
                }
            #endregion

            #region Pipeline
                void FindProperties(MaterialProperty[] props) {
                    
                    m_editFlag = EditFlag.None;

                    // Lit
                    blendMode           = FindProperty("_Blend", props, false);
                    albedoMap           = FindProperty("_MainTex", props);
                    albedoColor         = FindProperty("_Color", props);
                    alphaCutoff         = FindProperty("_Cutoff", props, false);
                    rampMap             = FindProperty("_ToonTex", props);
                    rampPointMap        = FindProperty("_ToonPointLightTex", props);
                    rampFactor          = FindProperty("_ToonFactor", props);
                    occlusionFactor     = FindProperty("_OcclusionStrength", props);
                    occlusionMap        = FindProperty("_OcclusionMap", props);
                    emissionColor       = FindProperty("_EmissionColor", props);
                    emissionMap         = FindProperty("_EmissionMap", props);
                    // Outline
                    lineColor   = FindProperty("_OutlineColor", props, false);
                    lineSize    = FindProperty("_OutlineSize", props, false);
                    lineCull    = FindProperty("_OutlineCull", props, false);
                    // Option
                    cullMode                = FindProperty("_Cull", props);
                    useStandardGI           = FindProperty("_UseStandardGI", props);

                    if( blendMode!=null && alphaCutoff!=null )
                    {
                        m_editFlag |= EditFlag.ModeEditable;
                    }
                    if(lineColor!=null && lineSize!=null)
                    {
                        m_editFlag |= EditFlag.Line;
                    }
                    m_editFlag |= EditFlag.Lit;
                }

                void MaterialChanged(Material mtl) {

                    var bl = (m_editFlag&EditFlag.ModeEditable)!=0 ? (BlendMode)mtl.GetFloat("_Blend") : BlendMode.Opaque;
                    
                    SetupMaterialWithBlendMode(mtl, bl);
                    SetMaterialKeywords(mtl);
                }

                static void SetupMaterialWithBlendMode(Material mtl, BlendMode mode) {

                    switch(mode)
                    {
                        case BlendMode.Opaque:
                            mtl.DisableKeyword("NWH_TOON_CUTOUT");
                            break;
                        case BlendMode.Cutoff:
                            mtl.EnableKeyword("NWH_TOON_CUTOUT");
                            break;
                        default:
                            break;
                    }
                }

                static void SetMaterialKeywords(Material mtl) {

                    // Emission
                    bool shouldEmissionBeEnabled = ShouldEmissionBeEnabled(mtl, mtl.GetColor("_EmissionColor"));
                    SetKeyword(mtl, "_EMISSION", shouldEmissionBeEnabled);
                    // GI Mode
                    SetKeyword(mtl, "NWH_TOON_STANDARDGI", mtl.GetFloat("_UseStandardGI")==1f);

                    // Lightmap emissive
                    var flags = mtl.globalIlluminationFlags;
                    if( 0 != (flags & (MaterialGlobalIlluminationFlags.BakedEmissive | MaterialGlobalIlluminationFlags.RealtimeEmissive)) )
                    {
                        flags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
                        if( !shouldEmissionBeEnabled )
                        {
                            flags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;
                        }
                        mtl.globalIlluminationFlags = flags;
                    }
                }

                static void TryLocalize() {
                    var obj = (TextAsset)EditorGUIUtility.Load("HoshiyukiToonEditor/Localization/HoshiyukiToonEditor_" + Application.systemLanguage.ToString() + ".json");
                    if( obj )
                    {
                        EditorJsonUtility.FromJsonOverwrite(obj.text, s_styles);
                    }
                }
			#endregion

			#region Methods
                static bool ShouldEmissionBeEnabled(Material mtl, Color col) 
                {
                    bool realtimeEmission = 0 != (mtl.globalIlluminationFlags & MaterialGlobalIlluminationFlags.RealtimeEmissive);
                    return (col.maxColorComponent > 0.1f/255f) || realtimeEmission;
                }

                bool HasValidEmissiveKeyword(Material mtl) {
                    // See StandardShaderGUI.cs
                    bool hasEmissionKeyword = mtl.IsKeywordEnabled("_EMISSION");
                    return !( !hasEmissionKeyword && ShouldEmissionBeEnabled(mtl,emissionColor.colorValue) );
                }

                static void SetKeyword(Material mtl, string keyword, bool enabled) {

                    if(enabled)
                    {
                        mtl.EnableKeyword(keyword);
                    }
                    else
                    {
                        mtl.DisableKeyword(keyword);
                    }
                }
            #endregion
        #endregion
    }
}