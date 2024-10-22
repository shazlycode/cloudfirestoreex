import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isLoading = false;
  bool isDataLoading = false;
  bool isUpdateLoading = false;
  final db = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String? _searchItem = "";
  Map<String, dynamic> item = {"name": "", "lowerCaseName": "", "uses": ""};

  final _formKey = GlobalKey<FormState>();
  final _updateFormKey = GlobalKey<FormState>();

  Future<void> addMedicine() async {
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      } else {
        _formKey.currentState!.save();
        setState(() {
          isLoading = true;
        });
        await addItem();
        setState(() {
          isLoading = false;
        });
      }
    } on Exception catch (err) {
      print(err);
    }
  }

  Future<void> updateMedicine(String itemId) async {
    if (!_updateFormKey.currentState!.validate()) {
      return;
    }
    _updateFormKey.currentState!.save();

    try {
      setState(() {
        isUpdateLoading = true;
      });
      await updateItem(itemId);
      setState(() {
        isUpdateLoading = false;
      });
    } on Exception catch (err) {
      rethrow;
    }
  }

  Future addItem() async {
    await db.collection("drugs").add(item).then((onValue) {
      print(onValue.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Medicine adde successfully with id:${onValue.id}"),
      ));
    });
  }

  Future updateItem(String id) async {
    await db.collection("drugs").doc(id).update(item).then((onValue) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Medicine adde successfully"),
      ));
    });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> list = [];
  // List<Map<String, dynamic>>? items = [];
  // Future<void> getData() async {
  //   List<Map<String, dynamic>> fetched = [];
  //   try {
  //     setState(() {
  //       isDataLoading = true;
  //     });

  //     await db.collection("drugs").get().then((value) {
  //       for (var item in value.docs) {
  //         fetched.add(item.data());
  //       }
  //       items = fetched;
  //     });
  //     print(items);
  //     setState(() {
  //       isDataLoading = false;
  //     });
  //   } on Exception catch (err) {
  //     print(err);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("cloud firestore Ex".toUpperCase()),
        actions: [
          isLoading
              ? CircularProgressIndicator()
              : IconButton(
                  onPressed: () => addMedicine(), icon: Icon(Icons.add))
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _searchController,
              onChanged: (v) {
                setState(() {
                  _searchItem = v;
                });
              },
              decoration: const InputDecoration(
                  label: Text("Search"),
                  suffixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5)))),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return "Enter medicine name";
                            } else {
                              return null;
                            }
                          },
                          onSaved: (v) {
                            item = {
                              "name": v,
                              "lowerCaseName": v!.toLowerCase(),
                              "uses": item['uses']
                            };
                          },
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                              label: Text("Medicin Name"),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)))),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return "Enter Uses";
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                          onSaved: (v) {
                            item = {
                              "name": item["name"],
                              "lowerCaseName": item['lowerCaseName'],
                              "uses": v
                            };
                          },
                          decoration: const InputDecoration(
                              label: Text("Medicin Uses"),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)))),
                        ),
                      ],
                    )),
              )),
          Divider(),
          Expanded(
              flex: 3,
              child: Column(
                children: [
                  // isDataLoading
                  //     ? CircularProgressIndicator()
                  //     : ElevatedButton.icon(
                  //         onPressed: () => getData(),
                  //         icon: Icon(Icons.download),
                  //         label: Text("Get Data"),
                  //       ),
                  Expanded(
                      child: StreamBuilder(
                          stream: _searchController.text.isEmpty
                              ? db
                                  .collection("drugs")
                                  .orderBy('name', descending: true)
                                  // .where("name", isEqualTo: "Panadol")
                                  .snapshots()
                              : db
                                  .collection("drugs")
                                  .where("lowerCaseName",
                                      isGreaterThanOrEqualTo: _searchItem!)
                                  .where("lowerCaseName",
                                      isLessThan: '${_searchItem!}z')
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(child: Text("No Data Available"));
                            }
                            list = snapshot.data!.docs;

                            return ListView.builder(
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) => Card(
                                      child: Dismissible(
                                        direction: DismissDirection.endToStart,
                                        key: ValueKey(
                                            snapshot.data!.docs[index].id),
                                        onDismissed: (_) async {
                                          await db
                                              .collection("drugs")
                                              .doc(
                                                  snapshot.data!.docs[index].id)
                                              .delete();
                                        },
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          color: Colors.amberAccent,
                                          child: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                        ),
                                        child: ListTile(
                                          onTap: () {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return LayoutBuilder(builder:
                                                      (context, constraint) {
                                                    return AlertDialog(
                                                      title: Text("Update"),
                                                      content: SizedBox(
                                                        height: 200,
                                                        width: 400,
                                                        child: Form(
                                                            key: _updateFormKey,
                                                            child: Column(
                                                              children: [
                                                                TextFormField(
                                                                  initialValue: snapshot
                                                                          .data!
                                                                          .docs[
                                                                      index]["name"],
                                                                  validator:
                                                                      (v) {
                                                                    if (v ==
                                                                            null ||
                                                                        v.isEmpty) {
                                                                      return "Enter medicine name";
                                                                    } else {
                                                                      return null;
                                                                    }
                                                                  },
                                                                  onSaved: (v) {
                                                                    item = {
                                                                      "name": v,
                                                                      "lowerCaseName":
                                                                          v!.toLowerCase(),
                                                                      "uses": item[
                                                                          'uses']
                                                                    };
                                                                  },
                                                                  textInputAction:
                                                                      TextInputAction
                                                                          .next,
                                                                  decoration: const InputDecoration(
                                                                      label: Text(
                                                                          "Medicin Name"),
                                                                      border: OutlineInputBorder(
                                                                          borderRadius:
                                                                              BorderRadius.all(Radius.circular(5)))),
                                                                ),
                                                                const SizedBox(
                                                                  height: 15,
                                                                ),
                                                                TextFormField(
                                                                  initialValue: snapshot
                                                                          .data!
                                                                          .docs[
                                                                      index]["uses"],
                                                                  validator:
                                                                      (v) {
                                                                    if (v ==
                                                                            null ||
                                                                        v.isEmpty) {
                                                                      return "Enter Uses";
                                                                    }
                                                                    return null;
                                                                  },
                                                                  textInputAction:
                                                                      TextInputAction
                                                                          .next,
                                                                  onSaved: (v) {
                                                                    item = {
                                                                      "name": item[
                                                                          "name"],
                                                                      "lowerCaseName":
                                                                          item[
                                                                              'lowerCaseName'],
                                                                      "uses": v
                                                                    };
                                                                  },
                                                                  decoration: const InputDecoration(
                                                                      label: Text(
                                                                          "Medicin Uses"),
                                                                      border: OutlineInputBorder(
                                                                          borderRadius:
                                                                              BorderRadius.all(Radius.circular(5)))),
                                                                ),
                                                                ElevatedButton(
                                                                    onPressed:
                                                                        () async {
                                                                      await updateMedicine(snapshot
                                                                              .data!
                                                                              .docs[index]
                                                                              .id)
                                                                          .then((_) {
                                                                        return Navigator.pop(
                                                                            context);
                                                                      });
                                                                    },
                                                                    child: isUpdateLoading
                                                                        ? CircularProgressIndicator()
                                                                        : Text(
                                                                            "Update"))
                                                              ],
                                                            )),
                                                      ),
                                                    );
                                                  });
                                                });
                                          },
                                          title: Text(snapshot.data!.docs[index]
                                              ['name']),
                                          subtitle: Text(list[index]['uses']),
                                        ),
                                      ),
                                    ));
                          }))
                ],
              )),
        ],
      ),
    );
  }
}
