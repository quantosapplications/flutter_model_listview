
import 'package:flutter_model_listview/src/widgets/bottom_loader.dart';
import 'package:flutter_model_listview/src/widgets/center_loading.dart';
import 'package:flutter_model_listview/src/widgets/retry_button.dart';
import 'package:flutter_model_listview/src/widgets/scroll_listener.dart';
import 'package:flutter_model_listview/src/widgets/searching_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_throttling/flutter_throttling.dart';

typedef ModelListViewBuilder<T> = Widget Function(BuildContext context, int index, T element);

class ModelListView<T> extends StatefulWidget {

  /// The list of element to be rendered
  final List<T> list;
  
  /// Function to be called for load new elements
  /// Needed
  final Future<void> Function() load;

  /// bool parameters to tell [ModelListView] when stop to load more elements
  /// if not specified [ModelListView] will try to call [load] method undefinitely
  final bool loadedAll;

  /// The default behaviour of [ModelListView] is to call [load] method in the [initState]
  /// If this is not wanted set [doNotLoadOnInit] to [false]
  final bool doNotLoadOnInit;


  /// Function to be called when refresh happens. 
  /// Useless if sliver
  final Future<void> Function()? refresh; 

  /// [ScrollController] to be used with [ModelListView].
  /// Needed if sliver
  final ScrollController? scrollController; // needed if sliver

  /// Threshold of when [load] method will be called
  final double treshold;

  /// When [error] is not null it will be rendered [errorBuilder] on the end of the list
  /// Useful to create a "try again" widget
  final String? error;


  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Widget that will be rendered on the first [load] and at the end of the list
  /// Default will be [CenterLoading]
  final Widget? loadingWidget;

  /// Widget that will be rendered when [list] is empty and [load] method does not return any elements
  final Widget? noResultsWidget;

  /// Widget that will be rendered at the end of the list
  /// Default is [CenterLoading]
  final Widget? bottomLoader;

  /// Widget that will be rendered as the first child of the list
  /// Optional
  final Widget? firstChild;

  /// Builder method for the single element of the [list]
  final ModelListViewBuilder<T> builder;

  final bool reverse;

  final bool _sliver;
  final bool _grid;

  const ModelListView({
    Key? key, 
    required this.list, required this.load, required this.loadedAll, required this.builder, 
    this.doNotLoadOnInit = false,
    this.refresh, this.error, 
    this.treshold = 200,
    this.errorBuilder, this.loadingWidget, this.noResultsWidget, this.bottomLoader ,
    this.firstChild,
    this.reverse = false
  }) : 
    _sliver = false,
    _grid = false,
    scrollController = null,
    super(key: key);

  const ModelListView.withScrollController({
    Key? key, 
    required this.list, required this.load, required this.loadedAll, required this.builder, 
    this.doNotLoadOnInit = false,
    this.refresh, this.error, 
    this.scrollController,
    this.treshold = 200,
    this.errorBuilder, this.loadingWidget, this.noResultsWidget, this.bottomLoader ,
    this.firstChild,
    this.reverse = false
  }) : 
    _sliver = false,
    _grid = false,
    super(key: key);

  const ModelListView.sliver({
    Key? key, 
    required this.list, required this.load, required this.loadedAll, required this.builder, 
    this.doNotLoadOnInit = false,
    this.error, 
    required this.scrollController, this.treshold = 200,
    this.errorBuilder, this.loadingWidget, this.noResultsWidget, this.bottomLoader ,
    this.firstChild
  }) :
    refresh = null,
    _sliver = true,
    _grid = false,
    reverse = false,
    super(key: key);


  const ModelListView.grid({
    Key? key, 
    required this.list, required this.load, required this.loadedAll, required this.builder, 
    this.refresh, this.error, 
    this.doNotLoadOnInit = false,
    this.scrollController, this.treshold = 400, //più alto rispetto alla list perchè il bottom loader occupa una riga di altezza
    this.errorBuilder, this.loadingWidget, this.noResultsWidget, this.bottomLoader ,
    this.firstChild,
    this.reverse = false
  }) : 
    _sliver = false,
    _grid = true,
    super(key: key);

  const ModelListView.gridSliver({
    Key? key, 
    required this.list, required this.load, required this.loadedAll, required this.builder, 
    required this.scrollController, this.treshold = 400,
    this.doNotLoadOnInit = false,
    this.error, 
    this.errorBuilder, this.loadingWidget, this.noResultsWidget, this.bottomLoader ,
    this.firstChild
  }) :
    refresh = null,
    _sliver = true,
    _grid = true,
    reverse = false,
    super(key: key);

  @override
  _ModelListViewState<T> createState() => _ModelListViewState<T>();
}

class _ModelListViewState<T> extends State<ModelListView<T>> {

  Throttling? throttling;

  @override 
  void initState(){

    if (!widget.doNotLoadOnInit){
      widget.load(); 
    }
    
    
    if (widget._sliver && widget.scrollController != null) {
      widget.scrollController!.addListener(_onScroll);
      throttling = Throttling(duration: Duration(milliseconds: 500));
    }
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

        if(widget.list.isNotEmpty){

          var list;
          if (widget._grid) {
            if (widget._sliver) {
              list = SliverGrid(

                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    if (widget.firstChild != null) index--;
                    return _builder(index);
                  },
                  
                  childCount: widget.list.length + 3 + (widget.firstChild != null ? 1 : 0),
                ),
              );
            }
            else {
              list = GridView.builder(
      
                itemCount: widget.list.length + 3 + (widget.firstChild != null ? 1 : 0),
                shrinkWrap: false,
                physics: AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(4.0),
                reverse: widget.reverse,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  mainAxisSpacing: 4.0,
                  crossAxisSpacing: 4.0
                ),
                itemBuilder: (BuildContext context, int index) {
                  if (widget.firstChild != null) index--;
                  return _builder(index);
                }
            );
            }
            
          }
          else {
            if (widget._sliver) {
              list = SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    if (widget.firstChild != null) index--;
                    return _builder(index);
                  },
                  childCount: widget.list.length + 1,
                ),
              );
            }
            else {
              list = ListView.builder(
                cacheExtent: MediaQuery.of(context).size.height * 10,
                physics: AlwaysScrollableScrollPhysics(),
                controller: widget.scrollController,
                itemCount: widget.list.length + 1,
                reverse: widget.reverse,
                itemBuilder: (BuildContext context, int index) {
                  if (widget.firstChild != null) index--;
                  return _builder(index);
                }
              );
            }
          }
          if(widget.refresh != null && !widget._sliver) {
            list = RefreshIndicator(
              child: list,
              onRefresh: widget.refresh!,

            );
          }
          if (!widget._sliver) {
            list = ScrollListener(
              child: list,
              treshold: widget.treshold,
              onEndReach: widget.load,
              reverse: widget.reverse,
            );
          }
          
          return list;

        }
        else {
          Widget child;
          if(widget.error != null) { 
            child = widget.errorBuilder != null 
              ? widget.errorBuilder!(context, widget.error ?? '') 
              : Padding(
                padding: const EdgeInsets.symmetric(vertical: 16), 
                child: RetryButton(onPressed: widget.load)
              ); 
          }
          else if(widget.list.isEmpty) { 
            child = SearchingWidget(loadedAll: widget.loadedAll, loadingWidget: widget.loadingWidget, noResultsWidget: widget.noResultsWidget); 
          }
          else { 
            child = widget.loadingWidget ?? CenterLoading(); 
          }
          if(widget._sliver) { child = SliverFillRemaining(child: child); }
          return child; 
        } 

  }

  Widget _builder(int index) {
    if (index == -1 && widget.firstChild != null) { return widget.firstChild!; }

    if(index >= widget.list.length) {
      var child;
      if (widget.error != null) {
        child = widget.errorBuilder != null ? widget.errorBuilder!(context, widget.error!) : Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: RetryButton(onPressed: widget.load));
      }
      else {
        child = widget.bottomLoader ?? Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: BottomLoader(loadedAll: widget.loadedAll));
      }
      if (widget._grid) {
        child = _adjustLastGridChild(listLength: widget.list.length, index: index, child: child);
      }
      return child;
    } 
    else {
      return widget.builder(context, index, widget.list[index]);
    }

  }

  void _onScroll() {
    if (!widget.loadedAll && widget.error == null) {
      final maxScroll = widget.scrollController!.position.maxScrollExtent;
      final currentScroll = widget.scrollController!.position.pixels;
      if (currentScroll >= maxScroll - widget.treshold) {
        if (mounted) { throttling?.throttle(widget.load); }
      }
    }
    
  }

  Widget _adjustLastGridChild({required int listLength, required int index, required Widget child}) {
    if (listLength % 3 == 0 && index == listLength + 1) {
      return child; 
    }
    else if (listLength % 3 == 1 && index == listLength) {
       return child; 
    }
    else if (listLength % 3 == 2 && index == listLength + 2) {
       return child; 
    }
    else {
      return Container();
    } 
    
  }

  @override
  void dispose() { 
    if (widget.scrollController != null){
      widget.scrollController!.removeListener(_onScroll);
    }
    throttling?.dispose();
    
    
    super.dispose();
  }
}
