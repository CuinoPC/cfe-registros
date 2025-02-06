import 'package:cfe_registros/views/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'user_list.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserList()),
            );
          },
          child: Text("Ver Usuarios"),
        ),
      ),
    );
  }
}
