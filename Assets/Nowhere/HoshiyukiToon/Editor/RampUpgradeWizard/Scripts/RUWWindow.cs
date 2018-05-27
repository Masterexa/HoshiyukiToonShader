using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using System;
using System.IO;

namespace HoshiyukiToonShaderEditor.RampUpgradeWizard{


    /* --- WARNING ---

    Create this only in under the 'Editor' directory.

    */
    
    class TargetMaterial {
        public bool     enabled;
        public Material material;
    }

    [System.Flags]
    public enum RampUpgradeOptions {
        CopyFromDirectional = 0x1,
        ApplySingleTexture  = 0x2,
        Asynchronously      = 0x4
    }

    public struct RampUpgraderMaterialPair{
        public bool     isScheduled;
        public string   path;
        public Material material;
    }

    public static class RampUpgrader {


        #region Methods
            public static void UpgradeMaterials(Material[] materials, RampUpgradeOptions type=RampUpgradeOptions.CopyFromDirectional, Texture2D pointRampTexture=null) {

                var     directionalTexId    = Shader.PropertyToID("_ToonTex");
                var     pointTexId          = Shader.PropertyToID("_ToonPointLightTex");
                bool    isCopyFromDir       = (type & RampUpgradeOptions.CopyFromDirectional)!=0;
                bool    isAsync             = (type & RampUpgradeOptions.Asynchronously)!=0;

                
                for(int i=0; i!=materials.Length; ++i)
                {
                    var it = materials[i];

                    it.SetTexture(
                        pointTexId,
                        isCopyFromDir ? it.GetTexture(directionalTexId) : pointRampTexture
                    );

                    if( isAsync )
                    {
                        EditorUtility.DisplayProgressBar(
                            "Upgrading Mateials", string.Format("({0}/{1}){2}", i+1, materials.Length, it.name),
                            (float)i/(float)materials.Length
                        );
                    }
                }
                if( isAsync )
                {
                    EditorUtility.ClearProgressBar();
                }
                
            }

            public static void FindUnupdatedMaterials(out RampUpgraderMaterialPair[] pairs) {

                var myShaders = new []{
                    Shader.Find("HoshiyukiToon/Lit"),
                    Shader.Find("HoshiyukiToon/LitFade"),
                    Shader.Find("HoshiyukiToon/LitOutline"),
                    Shader.Find("HoshiyukiToon/LitFadeOutline")
                };
                var pointTexId = Shader.PropertyToID("_ToonPointLightTex");

                pairs = AssetDatabase.FindAssets("t:Material")
                    .Select( (it)=>AssetDatabase.GUIDToAssetPath(it) )
                    .Select( (it)=>new RampUpgraderMaterialPair {
                        path = it,
                        material = AssetDatabase.LoadAssetAtPath<Material>(it),
                        isScheduled = true
                    })
                    .Where((it)=>
                    {
                        if( !myShaders.Any( (shader)=>(it.material.shader==shader) ) )
                        {
                            return false;
                        }
                        return it.material.GetTexture(pointTexId)==null;
                    })
                    .ToArray()
                ;
            }
        #endregion
    }



    class FileTreeBuilder {

        private RampUpgraderMaterialPair[] materials { get; set; }


        Dictionary<string,TreeViewItem> m_directries = new Dictionary<string, TreeViewItem>();
        int m_counter=0;

        public FileTreeBuilder() {
            this.materials = materials;
        }

        public void BuildTree(TreeViewItem root, RampUpgraderMaterialPair[] pathes) {

            this.materials = pathes;

            for(int i = 0; i<pathes.Length; i++)
            {
                var it = pathes[i];
                var item = CreateFileItem(i, it.path);
                AddParent(it.path, item, root);
            }
            m_counter=0;
            m_directries.Clear();
        }

        void AddParent(string path, TreeViewItem child, TreeViewItem root) {

            string  dir     = Path.GetDirectoryName(path);
            if(string.IsNullOrEmpty(dir))
            {
                root.AddChild(child);
                return;
            }
            TreeViewItem    parent  = null;
            bool            isFound = m_directries.TryGetValue(dir, out parent);

            if(!isFound)
            {
                parent = CreateDirectryItem(dir);
                m_directries.Add(dir, parent);
                AddParent(dir, parent, root);
            }
            parent.AddChild(child);
        }

        TreeViewItem CreateFileItem(int idx, string path)
        {
            return CreateItem(idx, path);
        }

        TreeViewItem CreateDirectryItem(string path)
        {
            return CreateItem(materials.Length + (m_counter++), path);
        }

        TreeViewItem CreateItem(int id, string path)
        {
            return new TreeViewItem(id, -1, Path.GetFileNameWithoutExtension(path));
        }
    }



    class MaterialTreeView : TreeView {
        
        #region GUI Resources
            static Texture2D    s_FolderIcon    = EditorGUIUtility.FindTexture("Folder Icon");
            static Texture2D    s_MaterialIcon  = EditorGUIUtility.FindTexture("Material Icon");
            static GUIStyle     s_toggleMixed   = new GUIStyle("ToggleMixed");
        #endregion


        #region Instance
            #region Fields
                public RampUpgraderMaterialPair[] m_materialPairs;
            #endregion

            #region GUI Events
                protected override void SelectionChanged(IList<int> selectedIds) {

                    base.SelectionChanged(selectedIds);
                }

                protected override void RowGUI(RowGUIArgs args) {

                    var ev = Event.current;
                    extraSpaceBeforeIconAndLabel = 36f; //18
                    

                    // Get aseet type is Folder or Material
                    var iconTex = (args.item.id<m_materialPairs.Length) ? s_MaterialIcon : s_FolderIcon;

                    Rect    toggleRc = args.rowRect,
                            iconRc;
                    toggleRc.x          += GetContentIndent(args.item);
                    toggleRc.width      = 16f;
                    iconRc              = toggleRc;
                    iconRc.x            += toggleRc.width;

                    if( (ev.type==EventType.MouseDown) )
                    {
                        if( (ev.button==1) && args.rowRect.Contains(ev.mousePosition) )
                        {
                            SelectionClick(args.item, true);
                            OnRightClickMenu(args);
                        }
                        else if( (ev.button==1) && toggleRc.Contains(ev.mousePosition) )
                        {
                            SelectionClick(args.item, false);
                        }
                    }
                    
                    DoToggle(toggleRc, args.item);


                    GUI.DrawTexture(iconRc, iconTex);
                    base.RowGUI(args);
                }

                void DoToggle(Rect rect, TreeViewItem item) {

                    var ret     = CheckRecursive(item);
                    var value   = ret==true || ret==null;

                    using(var chk = new EditorGUI.ChangeCheckScope())
                    {
                        value = EditorGUI.Toggle(rect, value, (ret==null) ? s_toggleMixed : EditorStyles.toggle);
                        if( chk.changed )
                        {
                            ChangeRecursive(item, value);
                        }
                    }
                }

                bool? CheckRecursive(TreeViewItem item)
                {
                    if( item.hasChildren )
                    {
                        int t=0, f=0;

                        foreach(var it in item.children)
                        {
                            var ret = CheckRecursive(it);
                            if( ret==true )
                            {
                                t++;
                            }
                            else if( ret==false )
                            {
                                f++;
                            }
                            else
                            {
                                return null;
                            }
                        }

                        return (t!=0 && f!=0) ? (bool?)null : (t!=0);
                    }

                    return m_materialPairs[item.id].isScheduled;
                }

                void ChangeRecursive(TreeViewItem item, bool b) {
                    
                    if( item.hasChildren )
                    {
                        foreach(var it in item.children)
                        {
                            ChangeRecursive(it, b);
                        }
                    }
                    else
                    {
                        m_materialPairs[item.id].isScheduled = b;
                    }
                }
            #endregion
        #endregion


        public MaterialTreeView(TreeViewState state) : base(state) {

            showAlternatingRowBackgrounds = true;
            this.showBorder = true;
        }

        protected override TreeViewItem BuildRoot()
        {
            var root    = new TreeViewItem(-1, -1, "");
            var buider  = new FileTreeBuilder();

            buider.BuildTree(root, m_materialPairs);
            SetupDepthsFromParentsAndChildren(root);
            return root;
        }

        public void Reload(RampUpgraderMaterialPair[] pathes) {
            m_materialPairs = pathes;
            Reload();
        }

        void OnRightClickMenu(RowGUIArgs args) {

            var menu = new GenericMenu();
            

            // Expand All
            menu.AddItem(new GUIContent("Expand All"), false, (obj) =>
            {
                SetExpandedRecursive((int)obj, true);
            }
            , args.item.id);

            // Collapse All
            menu.AddItem(new GUIContent("Collapse All"), false, (obj) =>
            {
                SetExpandedRecursive((int)obj, false);
            }
            , args.item.id);

            // Show right click menu
            menu.ShowAsContext();
        }
    }


	///<summary>RUWWindow</summary>
	///<remarks>
	///A Editor Window class.
	///</remarks>
	public class RUWWindow : EditorWindow{

        static RUWWindow main { get; set; }




        [MenuItem("HoshiyukiToon/Upgrade Ramp")]
        static void Init(){
            if( main==null )
            {
                main = CreateInstance<RUWWindow>();
            }
            main.ShowUtility();
        }


        class Page {
            public System.Action action { get; set; }

            public Page(System.Action action)
            {
                this.action = action;
            }
        }


        static GUIStyle s_footerStyle;


		#region Instance
			#region Fields
                Vector2 m_scroll;

                Dictionary<string,Page> m_pages = new Dictionary<string, Page>();
                Page        m_current;
                string      m_nextPage = "";
                string[]    m_pathes = new string[0];

                MaterialTreeView    m_treeView;
                TreeViewState       m_treeViewState;
                SearchField         m_searchField;

        
                Rect materialListRect {
                    get {
                        return new Rect(10f, 0f, position.width-20f, 300f);
                    }
                }
			#endregion

			#region Events
				///<summary>
				///Use this for initialization.
				///</summary>
				void OnEnable() {
                    s_footerStyle = (GUIStyle)"ProjectBrowserBottomBarBg";
            
                    if( m_treeViewState==null )
                    {
                        m_treeViewState = new TreeViewState();
                    }
                    m_treeView = new MaterialTreeView(m_treeViewState);

                    RampUpgraderMaterialPair[] pairs;
                    RampUpgrader.FindUnupdatedMaterials(out pairs);

                    m_treeView.Reload( pairs );
                    m_treeView.ExpandAll();


					m_pages.Add("1", new Page(Page1));
                    m_pages.Add("2", new Page(Page2));
                    m_pages.Add("3", new Page(Page3));
                    m_current = m_pages["1"];

                    m_searchField = new SearchField();
                    m_searchField.downOrUpArrowKeyPressed += m_treeView.SetFocusAndEnsureSelectedItem;
                }

                ///<summary>
                ///Use this for draw window.
                ///</summary>
                void OnGUI(){
                    using(var scr = new EditorGUILayout.ScrollViewScope(m_scroll))
                    {
                        if( m_current!=null )
                        {
                            m_current.action();
                        }
                        m_scroll = scr.scrollPosition;
                    }

                    using(var footer = new GUILayout.AreaScope(new Rect(0f,position.height-30f,position.width,30f),"", s_footerStyle))
                    {
                        using(var bottom = new EditorGUILayout.HorizontalScope())
                        {
                            if(GUILayout.Button("Next", EditorStyles.miniButton, GUILayout.ExpandWidth(false)))
                            {
                                NextPage();
                            }
                        }
                    }
                }
			#endregion

			#region Pipeline
                void Page1() {
                    EditorGUILayout.LabelField("もふもふ");
            
                    var rc = GUILayoutUtility.GetRect(0,100f,0,20);

                    rc.xMin += 20f;
                    rc.xMax -= 20f;
                    m_treeView.searchString = m_searchField.OnGUI(rc, m_treeView.searchString);

                    rc = GUILayoutUtility.GetRect(0, 100f, 0, 300);
                    rc.xMin += 20f;
                    rc.xMax -= 20f;
                    m_treeView.OnGUI(rc);        

                    SetNextPage("2");
                }

                void Page2() {
                    EditorGUILayout.LabelField("to");
                    SetNextPage("3");
                }

                void Page3() {
                    EditorGUILayout.LabelField("the world");
                    SetNextPage("1");
                }
			#endregion

			#region Methods
                void SetNextPage(string name) {
                    m_nextPage = name;
                }

                void NextPage() {
                    m_current = m_pages[m_nextPage];
                }
			#endregion
		#endregion
	}
}