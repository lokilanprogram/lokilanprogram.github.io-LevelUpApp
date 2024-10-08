import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';  // Для работы с JSON

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LevelUp App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Убираем баннер "debug"
      home: ProgressBarPage(),
    );
  }
}

class ProgressBarPage extends StatefulWidget {
  @override
  _ProgressBarPageState createState() => _ProgressBarPageState();
}

class _ProgressBarPageState extends State<ProgressBarPage> {
  final TextEditingController _goalController = TextEditingController();
  List<Map<String, dynamic>> _goals = []; // Список для хранения целей и прогресса

  @override
  void initState() {
    super.initState();
    _loadGoals(); // Загружаем сохранённые цели при запуске
  }

  // Загрузка целей из SharedPreferences
  Future<void> _loadGoals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? goalsJson = prefs.getString('goals');
    if (goalsJson != null) {
      setState(() {
        _goals = List<Map<String, dynamic>>.from(json.decode(goalsJson));
      });
    }
  }

  // Сохранение целей в SharedPreferences
  Future<void> _saveGoals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String goalsJson = json.encode(_goals);
    await prefs.setString('goals', goalsJson);
  }

  void _removeGoal(int index) {
    setState(() {
      _goals.removeAt(index);
    });
  }

  void _editGoal(int index) {
    TextEditingController editController = TextEditingController(text: _goals[index]['name']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Редактировать цель'),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(labelText: 'Новое название цели'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалог
              },
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _goals[index]['name'] = editController.text; // Обновляем название цели
                });
                _saveGoals(); // Сохраняем изменения
                Navigator.of(context).pop(); // Закрыть диалог
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  // Добавление новой цели
  void _addGoal() {
    String goal = _goalController.text;
    if (goal.isNotEmpty) {
      setState(() {
        _goals.add({
          'name': goal,
          'progress': 0.0,
        });
        _goalController.clear(); // Очищаем поле после добавления
      });
      _saveGoals(); // Сохраняем изменения
    }
  }

  // Увеличение прогресса для конкретной цели
  void _increaseGoalProgress(int index) {
    setState(() {
      if (_goals[index]['progress'] < 1.0) {
        _goals[index]['progress'] += 0.01;
      }
    });
    _saveGoals(); // Сохраняем изменения после увеличения прогресса
  }

  // Получение выполненных целей
  List<Map<String, dynamic>> getCompletedGoals() {
    return _goals.where((goal) => goal['progress'] >= 1.0).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LevelUp App'),
      ),
      drawer: Drawer( // Добавляем Drawer
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Меню',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Выполнено'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CompletedGoalsPage(completedGoals: getCompletedGoals()),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Форма для добавления новой цели
              TextField(
                controller: _goalController,
                decoration: InputDecoration(
                  labelText: 'Введите новую цель',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _addGoal,
                  child: Text('Добавить цель'),
                ),
              ),
              SizedBox(height: 20),

              // Отображаем список целей с прогресс-барами и кнопками
              ..._goals.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> goal = entry.value;
                bool isCompleted = goal['progress'] >= 1.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Текст прогресса
                      Text(
                        'Прогресс: ${(goal['progress'] * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      // Название цели с проверкой на завершение
                      Text(
                        goal['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.grey : Colors.black,
                          decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeGoal(index),
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: goal['progress'],
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      SizedBox(height: 10),
                      Center(
                      child: ElevatedButton(
                      onPressed: () => _increaseGoalProgress(index),
                      child: Text('Прогресс'),
                      ),
                    ),
                      SizedBox(height: 10),
                      Center(
                      child: ElevatedButton(
                      onPressed: () => _editGoal(index),  // Кнопка для редактирования цели
                      child: Text('Редактировать'),
                      ),
                    ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

// Страница выполненных целей
class CompletedGoalsPage extends StatelessWidget {
  final List<Map<String, dynamic>> completedGoals;

  CompletedGoalsPage({required this.completedGoals});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Выполненные цели'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: completedGoals.isEmpty
            ? Center(child: Text('Нет выполненных целей'))
            : ListView.builder(
                itemCount: completedGoals.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      completedGoals[index]['name'],
                      style: TextStyle(
                        fontSize: 18,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
