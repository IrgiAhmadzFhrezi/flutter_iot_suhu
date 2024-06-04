import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_iot_suhu/app_color.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();
  double? temperature;
  double? humidity;

  List<FlSpot> humidityData = [];
  List<FlSpot> temperatureData = [];
  int dataCount = 0;

  @override
  void initState() {
    super.initState();
    _databaseReference.child('sensor').onValue.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      setState(() {
        humidity = double.tryParse(data['kelembapan'].toString());
        temperature = double.tryParse(data['suhu'].toString());

        if (humidity! > 100) humidity = 100;
        if (temperature! > 100) temperature = 100;
        if (humidity! < 0) humidity = 0;
        if (temperature! < 0) temperature = 0;

        humidityData.add(FlSpot(dataCount.toDouble(), humidity!));
        temperatureData.add(FlSpot(dataCount.toDouble(), temperature!));

        // Limit the number of data points displayed
        if (humidityData.length > 6) humidityData.removeAt(0);
        if (temperatureData.length > 6) temperatureData.removeAt(0);

        dataCount++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set minX to show only the latest data
    double minX = (dataCount - humidityData.length).toDouble();

    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tambahkan ini
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sensor Data'),
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Card(
                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  humidity != null
                                      ? 'Humidity: $humidity%'
                                      : 'Loading Humidity...',
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Card(
                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  temperature != null
                                      ? 'Temperature: $temperature°C'
                                      : 'Loading Temperature...',
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (humidity != null && temperature != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child:
                                  _buildPieChart(humidity!, Colors.blueAccent),
                            ),
                            Expanded(
                              child: _buildPieChart(temperature!, Colors.red),
                            ),
                          ],
                        ),
                      if (humidity == null || temperature == null)
                        const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildLineChart(minX),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(double value, Color color) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 150,
        height: 150,
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                color: color,
                value: value,
              ),
              PieChartSectionData(
                color: Colors.blue.withOpacity(0.1),
                value: 100 - value,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(double minX) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Color(0xff37434d),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(
              color: Color(0xff37434d),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString());
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d)),
        ),
        minX: minX,
        maxX: dataCount.toDouble(),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: humidityData,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [AppColors.contentColorCyan, AppColors.contentColorBlue],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.contentColorCyan.withOpacity(0.3),
                  AppColors.contentColorBlue.withOpacity(0.3),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          LineChartBarData(
            spots: temperatureData,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [AppColors.contentColorRed, AppColors.contentColorOrange],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.contentColorRed.withOpacity(0.3),
                  AppColors.contentColorOrange.withOpacity(0.3),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
