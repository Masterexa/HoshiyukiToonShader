using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using System;
using System.IO;
using UnityObject = UnityEngine.Object;

namespace HoshiyukiToonShaderEditor.RampUpgradeWizard{

    /// <summary>
    /// \~english   Class for building a file tree.
    /// \~japanese  ファイルツリーの組み立てを行うクラス.
    /// </summary>
    class FileTreeBuilder {

        #region Fields
            RampUpgraderMaterialPair[] materials { get; set; }

            Dictionary<string,TreeViewItem> m_directries = new Dictionary<string, TreeViewItem>();
            int m_counter=0;
        #endregion

        #region Methods
            public FileTreeBuilder() {
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
        #endregion

        #region Internals
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
        #endregion
    }


    /// <summary>
    /// Tree view for material list in upgrader wizard.
    /// </summary>
    class MaterialTreeView : TreeView {
        
        #region GUI Resources
            static Texture2D    s_FolderIcon;
            static Texture2D    s_MaterialIcon;
            static GUIStyle     s_toggleMixed;
        #endregion

        static MaterialTreeView() {
            s_FolderIcon    = EditorGUIUtility.FindTexture("Folder Icon");
            s_MaterialIcon  = EditorGUIUtility.FindTexture("Material Icon");
            s_toggleMixed   = new GUIStyle("ToggleMixed");
        }


        #region Instance
            #region Fields
                RampUpgraderMaterialPair[] m_materialPairs;

                public int materialCount {
                    get { return m_materialPairs.Length; }
                }

                public int scheduledMaterialCount {
                    get { return m_materialPairs.Count( (it)=>it.isScheduled ); }
                }
            #endregion

            #region GUI Methods
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

                    var ret     = CheckScheduleRecursive(item);
                    var value   = ret==true || ret==null;

                    using(var chk = new EditorGUI.ChangeCheckScope())
                    {
                        value = EditorGUI.Toggle(rect, value, (ret==null) ? s_toggleMixed : EditorStyles.toggle);
                        if( chk.changed )
                        {
                            ChangeScheduleRecursive(item, value);
                        }
                    }
                }

                void OnRightClickMenu(RowGUIArgs args) {

                    var menu = new GenericMenu();

                    if(args.item.hasChildren)
                    {
                        menu.AddItem(new GUIContent("Open in Project"), false, (obj) =>
                        {
                            var item    = (TreeViewItem)obj;
                            var folder  = AssetDatabase.LoadAssetAtPath<UnityObject>( GetParentPath(item) );
                            EditorGUIUtility.PingObject(folder);
                        }, args.item);

                        menu.AddSeparator("");

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
                    }
                    else
                    {
                        menu.AddItem(new GUIContent("Open in Project"), false, (obj) =>
                        {
                            EditorGUIUtility.PingObject(m_materialPairs[(int)obj].material);
                        }, args.item.id);

                        menu.AddSeparator("");

                        menu.AddDisabledItem(new GUIContent("Expand All"));
                        menu.AddDisabledItem(new GUIContent("Collapse All"));
                    }

                    // Show right click menu
                    menu.ShowAsContext();
                }
            #endregion

            #region Tree Methods
                public MaterialTreeView(TreeViewState state) : base(state)
                {
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


                string GetParentPath(TreeViewItem item) {

                    var path = GetParentPathRecursive(item);
                    return path.Remove(path.Length-1);
                }

                string GetParentPathRecursive(TreeViewItem item){

                    if( item.parent==null )
                    {
                        return "";
                    }
                    return GetParentPathRecursive(item.parent) + item.displayName + '/';
                }

                bool? CheckScheduleRecursive(TreeViewItem item) {
                    if(item.hasChildren)
                    {
                        bool? firstVal = null;

                        foreach(var it in item.children)
                        {
                            var ret = CheckScheduleRecursive(it);

                            if( firstVal==null )
                            {
                                firstVal = ret;
                            }

                            // Check
                            if( ret==null || (ret!=firstVal) )
                            {
                                firstVal = null;
                                break;
                            }
                        }

                        return firstVal;
                    }

                    return m_materialPairs[item.id].isScheduled;
                }

                void ChangeScheduleRecursive(TreeViewItem item, bool b) {

                    if(item.hasChildren)
                    {
                        foreach(var it in item.children)
                        {
                            ChangeScheduleRecursive(it, b);
                        }
                    }
                    else
                    {
                        m_materialPairs[item.id].isScheduled = b;
                    }
                }
            #endregion
        #endregion
    }


	///<summary>RUWWindow</summary>
	///<remarks>
	///A Editor Window class.
	///</remarks>
	public class RampUpgradeWizard : EditorWindow{

        static RampUpgradeWizard main { get; set; }

        [MenuItem("HoshiyukiToon/Upgrade Ramp")]
        static void Init(){
            if( main==null )
            {
                main = CreateInstance<RampUpgradeWizard>();
            }
            main.ShowUtility();
        }


        #region Typedefs
            class Page {
                public System.Action action { get; set; }

                public Page(System.Action action)
                {
                    this.action = action;
                }
            }

            enum PageNum {
                None = -1,
                MaterialListPage,
                OperationChoosenPage,
                DonePage,
                Finished
            }
        #endregion


        #region GUI Resources
            static RectOffset   s_padding = new RectOffset(20,20,10,40);
            static GUIStyle     s_headerLabelStyle;
            static GUIContent   s_refreshButtonContent;
            static GUIContent   s_titleContent;
        #endregion


        static RampUpgradeWizard() {
            s_refreshButtonContent      = new GUIContent("Refresh", EditorGUIUtility.FindTexture("RotateTool"), "");
            s_titleContent              = new GUIContent("Upgrade Ramp Texture");

            s_headerLabelStyle          = new GUIStyle(EditorStyles.largeLabel);
            s_headerLabelStyle.font     = EditorStyles.boldFont;
            s_headerLabelStyle.fontSize = 18;

            var normal                  = s_headerLabelStyle.normal;
            normal.textColor            = new Color(0.4f, 0.4f, 0.4f);
            s_headerLabelStyle.normal   = normal;
        }



        #region Instance
            #region UI States
                Dictionary<PageNum,Page> m_pages = new Dictionary<PageNum, Page>();

                // Page States
                PageNum m_currentPage   = PageNum.MaterialListPage;
                PageNum m_nextPage      = PageNum.Finished;
                PageNum m_prevPage      = PageNum.None;

                // UI Elements
                MaterialTreeView    m_treeView;
                TreeViewState       m_treeViewState;
                SearchField         m_searchField;
                
                Rect materialListRect {
                    get {
                        return new Rect(10f, 0f, position.width-20f, 300f);
                    }
                }

                Rect pageRect {
                    get {
                        return new Rect(
                            s_padding.left,
                            s_padding.top,
                            position.width - s_padding.right - s_padding.left,
                            position.height - s_padding.top - s_padding.bottom
                        );
                    }
                }
            #endregion

            #region Options
                Texture2D           m_pointRampTex;
                RampUpgradeOptions  m_upgradeOptions    = RampUpgradeOptions.Asynchronously;
            #endregion

            #region Events
                ///<summary>
                ///Use this for initialization.
                ///</summary>
                void OnEnable() {
                    // Apply Title
                    this.titleContent   = s_titleContent;

                    // Init TreeView
                    if( m_treeViewState==null )
                    {
                        m_treeViewState = new TreeViewState();
                    }
                    m_treeView = new MaterialTreeView(m_treeViewState);

                    // Init SearchField
                    m_searchField = new SearchField();
                    m_searchField.downOrUpArrowKeyPressed += m_treeView.SetFocusAndEnsureSelectedItem;

                    // Register pages
					m_pages.Add(PageNum.MaterialListPage, new Page(DoMaterialListPage));
                    m_pages.Add(PageNum.OperationChoosenPage, new Page(DoOperationChoosenPage));
                    m_pages.Add(PageNum.DonePage, new Page(DoDonePage));

                    RefreshMaterialList();
                }

                ///<summary>
                ///Use this for draw window.
                ///</summary>
                void OnGUI(){
            
                    // Draw Content
                    using(var scr = new GUILayout.AreaScope(this.pageRect)){
                        if( m_currentPage!=PageNum.None )
                        {
                            m_pages[m_currentPage].action();
                        }
                    }
                    
                    // Footer area
                    using(var footer = new GUILayout.AreaScope(new Rect(10f,position.height-30f,position.width-20f,30f),"")){
                    using(var bottom = new EditorGUILayout.HorizontalScope())
                    {
                        // Back button
                        using(var dis = new EditorGUI.DisabledScope(m_prevPage==PageNum.None))
                        {
                            if( GUILayout.Button("Back", GUILayout.ExpandWidth(false)) )
                            {
                                PrevPage();
                            }
                        }
                            
                        // Space between Back and Cancel
                        GUILayout.FlexibleSpace();

                        // Cancel button
                        if( GUILayout.Button("Cancel", GUILayout.ExpandWidth(false)) )
                        {
                            DisplayCancelDialog();
                        }
                            
                        // Next & Finish button
                        using(var dis = new EditorGUI.DisabledScope(m_nextPage==PageNum.None))
                        {
                            var label = (m_nextPage==PageNum.Finished) ? "Finish" : "Next";

                            if( GUILayout.Button(label, GUILayout.ExpandWidth(false)) )
                            {
                                NextPage();
                            }
                        }
                    }}// End of footer area
                                  
                }// End of OnGUI()
			#endregion

			#region Pages
                void DoMaterialListPage() {
                    DoHeaderLabel(new GUIContent("Select Materials"));
            
                    // Draw Search field
                    var rc = GUILayoutUtility.GetRect(0,100f,0,20);
                    m_treeView.searchString = m_searchField.OnGUI(rc, m_treeView.searchString);

                    // Draw Tree view
                    rc = GUILayoutUtility.GetRect(0, 100f, 0, 300);
                    m_treeView.OnGUI(rc);        

                    // Refresh button
                    if( GUILayout.Button(s_refreshButtonContent, GUILayout.ExpandWidth(false)) )
                    {
                        RefreshMaterialList();
                    }

                    // Display num
                    GUILayout.Label(string.Format("Selected {0} of {1}.", m_treeView.scheduledMaterialCount, m_treeView.materialCount));

                    // Page setting
                    SetPrevPage(PageNum.None);
                    SetNextPage( (m_treeView.scheduledMaterialCount!=0) ? PageNum.OperationChoosenPage : PageNum.None);
                }

                void DoOperationChoosenPage() {
                    
                    bool isCopyFromDir  = !((m_upgradeOptions & RampUpgradeOptions.CopyFromDirectional)==0);

                    // Draw header
                    DoHeaderLabel(new GUIContent("Options"));

                    // Draw options
                    EditorGUILayout.Space();
                    isCopyFromDir       = GUILayout.Toggle(isCopyFromDir, "Copy from Directional", EditorStyles.radioButton);
                    isCopyFromDir       = !GUILayout.Toggle(!isCopyFromDir, "Apply Single Texture", EditorStyles.radioButton);

                    // Draw texture setting
                    EditorGUI.indentLevel++;
                    EditorGUI.BeginDisabledGroup(isCopyFromDir);
                    using(var box = new GUILayout.VerticalScope(EditorStyles.helpBox))
                    {
                        m_pointRampTex = (Texture2D)EditorGUILayout.ObjectField("Point Light Ramp", m_pointRampTex, typeof(Texture2D), false);
                    }
                    EditorGUI.EndDisabledGroup();
                    EditorGUI.indentLevel--;

                    // Apply options
                    m_upgradeOptions    = RampUpgradeOptions.Asynchronously | (isCopyFromDir ? RampUpgradeOptions.CopyFromDirectional : RampUpgradeOptions.ApplySingleTexture);

                    // Set page
                    SetPrevPage(PageNum.MaterialListPage);
                    SetNextPage(PageNum.DonePage);
                }

                void DoDonePage() {
                    DoHeaderLabel(new GUIContent("Finished"));
                    GUILayout.Label("てふてふ");

                    SetPrevPage(PageNum.None);
                    SetNextPage(PageNum.Finished);
                }
			#endregion

			#region Methods
                void DoHeaderLabel(GUIContent content) {
                    var rc  = GUILayoutUtility.GetRect(0f, s_headerLabelStyle.CalcHeight(content, this.pageRect.width));
                    GUI.Label(rc, content, s_headerLabelStyle);
                    EditorGUILayout.Space();
                }

                void SetPrevPage(PageNum num) {
                    m_prevPage = num;
                }

                void SetNextPage(PageNum num) {
                    m_nextPage = num;
                }

                void NextPage() {
                    if( m_nextPage==PageNum.Finished )
                    {
                        this.Close();
                    }
                    else
                    {
                        m_currentPage = m_nextPage;
                    }
                }

                void PrevPage() {
                    m_currentPage = m_prevPage;
                }

                void DisplayCancelDialog() {
                    if( EditorUtility.DisplayDialog("確認", "セットアップをキャンセルしますか?", "はい", "いいえ") )
                    {
                        SetNextPage(PageNum.DonePage);
                        NextPage();
                    }
                        
                }

                void RefreshMaterialList() {
                    EditorUtility.DisplayProgressBar("Info", "Searching Materials", 1f);
                    {
                        RampUpgraderMaterialPair[] pairs;
                        RampUpgrader.FindUnupdatedMaterials(out pairs);
                        m_treeView.Reload( pairs );
                        m_treeView.ExpandAll();
                    }
                    EditorUtility.ClearProgressBar();
                }
			#endregion
		#endregion
	}
}