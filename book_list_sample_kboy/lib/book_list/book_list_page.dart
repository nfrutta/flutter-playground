import 'package:book_list_sample_kboy/add_book/add_book_page.dart';
import 'package:book_list_sample_kboy/domain/book.dart';
import 'package:book_list_sample_kboy/edit_book/edit_book_page.dart';
import 'package:book_list_sample_kboy/login/login_page.dart';
import 'package:book_list_sample_kboy/mypage/my_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import 'book_list_model.dart';

class BookListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BookListModel>(
      create: (_) => BookListModel()..fetchBookList(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('本一覧'),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: () async {
                  if (FirebaseAuth.instance.currentUser != null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyPage(),
                        fullscreenDialog: true,
                      ),
                    );
                  } else {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(),
                        fullscreenDialog: true,
                      ),
                    );
                  }
                },
                icon: Icon(Icons.person)),
          ],
        ),
        body: Center(
          child: Consumer<BookListModel>(builder: (context, model, child) {
            final List<Book>? books = model.books;

            if (books == null) {
              return CircularProgressIndicator();
            }

            final List<Widget> widgets = books
                .map(
                  (book) => Slidable(
                    actionPane: SlidableDrawerActionPane(),
                    child: ListTile(
                      leading: book.imgURL != null
                          ? Image.network(book.imgURL!)
                          : null,
                      title: Text(book.title),
                      subtitle: Text(book.author),
                    ),
                    secondaryActions: <Widget>[
                      IconSlideAction(
                        caption: '編集',
                        color: Colors.green,
                        icon: Icons.edit,
                        onTap: () async {
                          // 編集画面へ遷移
                          final String? title = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditBookPage(book),
                            ),
                          );

                          if (title != null) {
                            final snackBar = SnackBar(
                              backgroundColor: Colors.green,
                              content: Text('$title を編集しました'),
                            );
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          }

                          model.fetchBookList();
                        },
                      ),
                      IconSlideAction(
                        caption: '削除',
                        color: Colors.red,
                        icon: Icons.delete,
                        onTap: () async {
                          await showConfirmDialog(context, book, model);
                        },
                      ),
                    ],
                  ),
                )
                .toList();
            return ListView(
              children: widgets,
            );
          }),
        ),
        floatingActionButton:
            Consumer<BookListModel>(builder: (context, model, child) {
          return FloatingActionButton(
            onPressed: () async {
              // 画面遷移
              final bool? isAdded = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddBookPage(),
                  fullscreenDialog: true,
                ),
              );

              if (isAdded != null && isAdded) {
                final snackBar = SnackBar(
                  backgroundColor: Colors.green,
                  content: Text('本を追加しました'),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }

              model.fetchBookList();
            },
            tooltip: 'Increment',
            child: Icon(Icons.add),
          );
        }),
      ),
    );
  }

  Future showConfirmDialog(
      BuildContext context, Book book, BookListModel model) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text("削除の確認"),
          content: Text("『${book.title}』を削除しますか？"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("OK"),
              onPressed: () async {
                await model.deleteBook(book);
                Navigator.pop(context);
                final snackBar = SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('${book.title}を削除しました'),
                );
                model.fetchBookList();
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
            ),
          ],
        );
      },
    );
  }
}