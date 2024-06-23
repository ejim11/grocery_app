import "dart:convert";
import "dart:core";

import "package:flutter/material.dart";
import "package:grocery_app/data/categories.dart";
import "package:grocery_app/models/grocery_item.dart";
import "package:grocery_app/widgets/new_item.dart";
import "package:http/http.dart" as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;
  // String? _error;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'flutter-prep-bfc95-default-rtdb.firebaseio.com', 'shopping-list.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch grocery, please try again later');
      // setState(() {
      //   _error = 'failed to fetch data. please try again later';
      // });
    }

    if (response.body == 'null') {
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);

    final List<GroceryItem> loadedItems = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;

      loadedItems.add(
        GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category),
      );
    }

    return _loadItems();
  }

  void _addItems() async {
    final newItem =
        await Navigator.of(context).push<GroceryItem>(MaterialPageRoute(
      builder: (ctx) => const NewItem(),
    ));

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);

    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https('flutter-prep-bfc95-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Widget mainContent = const Center(
    //   child: Text('There are no items added yet.'),
    // );

    // if (_isLoading) {
    //   mainContent = const Center(child: CircularProgressIndicator());
    // }

    // if (_groceryItems.isNotEmpty) {
    //   mainContent =
    // }

    // if (_error != null) {
    //   mainContent = Center(child: Text(_error!));
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItems,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder(
          future: _loadedItems,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString(),
                ),
              );
            }

            if (snapshot.data!.isEmpty) {
              return const Center(
                child: Text('There are no items added yet.'),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (ctx, index) => Dismissible(
                background: Container(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.75),
                  margin: const EdgeInsets.fromLTRB(3, 0, 0, 0),
                ),
                onDismissed: (direction) {
                  _removeItem(snapshot.data![index]);
                },
                key: ValueKey(snapshot.data![index].id),
                child: ListTile(
                  title: Text(snapshot.data![index].name),
                  leading: Container(
                      width: 24,
                      height: 24,
                      color: snapshot.data![index].category.color),
                  trailing: Text(
                    snapshot.data![index].quantity.toString(),
                  ),
                ),
              ),
            );
          }),
    );
  }
}
