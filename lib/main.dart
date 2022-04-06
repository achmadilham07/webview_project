import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/data_sources/local_data_source.dart';
import 'data/data_sources/remote_data_source.dart';
import 'data/repository.dart';
import 'presentation/app_colors.dart';
import 'presentation/home/home_page_scaffold.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebView Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          accentColor: AppColors.secondaryColor,
        ),
        primaryColor: AppColors.primary,
        primaryColorDark: AppColors.primaryDark,
        appBarTheme:
            const AppBarTheme(systemOverlayStyle: SystemUiOverlayStyle.dark),
      ),
      home: HomePageScaffold(
        repository: Repository(
          LocalDataSource(),
          RemoteDataSource(),
        ),
      ),
    );
  }
}
