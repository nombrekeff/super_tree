// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Ejemplos de Super Tree';

  @override
  String get quickLinksTitle => 'Accesos rapidos';

  @override
  String get allExamplesTitle => 'Todos los ejemplos';

  @override
  String get exampleFileSystemTitle => 'Explorador de archivos';

  @override
  String get exampleFileSystemDescription =>
      'El ejemplo clasico de explorador con arrastrar y soltar y varios presets (VS Code, Material, Compact).';

  @override
  String get exampleCheckboxTitle => 'Checkboxes y estado';

  @override
  String get exampleCheckboxDescription =>
      'Un arbol de permisos que demuestra checkboxes con gestion recursiva de estado padre e hijo.';

  @override
  String get exampleComplexNodeTitle => 'UI de nodo complejo';

  @override
  String get exampleComplexNodeDescription =>
      'Un tablero de tareas con contenido de nodo enriquecido, avatares y acciones en linea.';

  @override
  String get exampleTodoTitle => 'Arbol de tareas';

  @override
  String get exampleTodoDescription =>
      'Un arbol preconstruido que demuestra checkboxes por defecto, modelos de datos y ordenamiento para tareas jerarquicas.';

  @override
  String get exampleSimpleFileSystemTitle => 'Sistema de archivos minimo';

  @override
  String get exampleSimpleFileSystemDescription =>
      'Un ejemplo minimalista para construir un arbol de archivos con cero boilerplate y datos fijos.';

  @override
  String get exampleAsyncLazyTitle => 'Carga diferida asincrona';

  @override
  String get exampleAsyncLazyDescription =>
      'Muestra carga bajo demanda de hijos con spinner y reintento de error al expandir nodos.';

  @override
  String get exampleIntegrityTitle => 'Protecciones de integridad';

  @override
  String get exampleIntegrityDescription =>
      'Demuestra protecciones contra IDs duplicados y referencias circulares con advertencias no fatales.';

  @override
  String get searchClear => 'Limpiar';

  @override
  String get searchClearSearch => 'Limpiar busqueda';

  @override
  String get searchCloseTooltip => 'Cerrar busqueda (Esc)';

  @override
  String get todoScreenTitle => 'Arbol de tareas';

  @override
  String get todoSearchTooltip => 'Buscar tareas (Cmd/Ctrl+F)';

  @override
  String get todoResortTooltip => 'Reordenar arbol';

  @override
  String get todoSearchHint => 'Buscar titulo, hecho o pendiente';

  @override
  String get todoDelete => 'Eliminar';

  @override
  String todoNoResults(Object query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String get todoClearSearch => 'Limpiar busqueda';

  @override
  String get todoDetailTitle => 'Ejemplo de tareas';

  @override
  String get todoDetailSubtitle =>
      'Marca tareas para verlas tachadas.\\nArrastra y suelta elementos para reorganizarlos.';

  @override
  String get fileScreenTitle => 'Arbol del sistema de archivos';

  @override
  String get fileSearchHint => 'Buscar archivos y carpetas';

  @override
  String get fileSearchTooltip => 'Buscar (Cmd/Ctrl+F)';

  @override
  String get fileSortNone => 'Sin ordenar';

  @override
  String get fileSortAlphabetical => 'Alfabetico';

  @override
  String get fileSortFoldersFirst => 'Carpetas primero';

  @override
  String get fileThemeVsCode => 'VS Code oscuro';

  @override
  String get fileThemeMaterial => 'Material';

  @override
  String get fileThemeCompact => 'Compacto';

  @override
  String get fileActionNewRootFolder => 'Nueva carpeta raiz';

  @override
  String get fileActionNewRootFile => 'Nuevo archivo raiz';

  @override
  String get fileActionExpandAll => 'Expandir todo';

  @override
  String get fileActionCollapseAll => 'Colapsar todo';

  @override
  String get fileRootMenuNewFile => 'Nuevo archivo';

  @override
  String get fileRootMenuNewFolder => 'Nueva carpeta';

  @override
  String get fileRootMenuExpandAll => 'Expandir todo';

  @override
  String get fileRootMenuCollapseAll => 'Colapsar todo';

  @override
  String get fileNodeMenuRename => 'Renombrar';

  @override
  String get fileNodeMenuDelete => 'Eliminar';

  @override
  String fileNoResults(Object query) {
    return 'Sin resultados para \"$query\"';
  }

  @override
  String get fileSelectHint =>
      'Selecciona un archivo para verlo\\nArrastra y suelta nodos para moverlos';

  @override
  String fileItemsSelected(int count) {
    return '$count elementos seleccionados';
  }

  @override
  String get fileDeleteSelected => 'Eliminar elementos seleccionados';

  @override
  String get fileTypeFolder => 'Carpeta';

  @override
  String get fileTypeFile => 'Archivo';

  @override
  String get fileRenameItem => 'Renombrar elemento';

  @override
  String fileRenamedTo(Object name) {
    return 'Renombrado a $name';
  }

  @override
  String get fileItemDeleted => 'Elemento eliminado';
}
