import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;


void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothApp(), // BluetoothApp() would be defined later
    );
  }
}


class BluetoothApp extends StatefulWidget {
  @override
  _BluetoothAppState createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;

  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _pressed = false;

  final Map<String, HighlightedWord> _highlights = {
    'flutter': HighlightedWord(
      onTap: () => print('flutter'),
      textStyle: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      ),
    ),
  };

  stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bluetoothConnectionState();
    _speech = stt.SpeechToText();
    _listen();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> bluetoothConnectionState() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // For knowing when bluetooth is connected and when disconnected
    bluetooth.onStateChanged().listen((BluetoothState bluetoothState) {

      print('On State change values ${bluetoothState.stringValue}');

      switch (bluetoothState.stringValue) {
        case 'STATE_ON':
          setState(() {
            _connected = true;
            _pressed = false;
          });

          break;

      //  case FlutterBluetoothSerial.DISCONNECTED:
        case 'STATE_OFF':
          setState(() {
            _connected = false;
            _pressed = false;
          });
          break;

        default:
          print('Bluetooth State : ${bluetooth.state}');
          break;
      }
    });

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }

  @override
  Widget build(BuildContext context) {

    final Map<String,HighlightedWord> _highlights = {
     'flutter':HighlightedWord(
       onTap: (){
         print('Flutter');
       }
     )


    };

    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("Flutter Bluetooth"),
          backgroundColor: Colors.deepPurple,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right:30.0),
              child: Icon(Icons.mic),
            ),
          ],
        ),
        body: ListView(
          children: <Widget>[
            SizedBox(
              height: 30.0,
            ),
            Text(
              "Available Devices",
              style: TextStyle(fontSize: 24, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.0,),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Center(
                    child: Text(
                      'Device:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 30.0,
                  ),
                  DropdownButton(
                    // To be implemented : _getDeviceItems()
                    items: _getDeviceItems(),
                    onChanged: (value) => setState(() => _device = value),
                    value: _device,
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 20.0,
            ),


            RaisedButton(
              onPressed:
              // To be implemented : _disconnect and _connect
              _pressed ? null : _connected ? _disconnect : _connect,
              child: Text(_connected ? 'Disconnect' : 'Connect'),
            ),

            SizedBox(
              height: 25.0,
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30.0,8.0,8.0,8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Switch",
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.indigo,
                      ),
                    ),

                    SizedBox(
                      width: 60.0,
                    ),
                    GestureDetector(
                      onTap: (){
                        print ('came inside gesturedetecture');
                        _sendOnMessageToBluetooth();
                      },
                      child: Container(
                        height: 40.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.indigo
                        ),
                        child: Center(
                          child: Text(
                            'ON',
                            style: TextStyle(
                              color: Colors.white
                            ),
                          ),
                        ),

                        ),
                    ),
                    GestureDetector(
                      onTap: (){
                        print ('came inside gesturedetecture');
                        _sendOffMessageToBluetooth();
                      },
                      child: Container(
                        height: 40.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Colors.indigo
                        ),
                        child: Center(
                          child: Text(
                            'OFF',
                            style: TextStyle(
                                color: Colors.white
                            ),
                          ),
                        ),

                      ),
                    ),

                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    "NOTE: If you cannot find the device in the list, "
                        "please turn on bluetooth and pair the device by "
                        "going to the bluetooth settings",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
              child: TextHighlight(
                text: 'bha bhab bha',
               // words: _highlights,
                textStyle: const TextStyle(
                  fontSize: 32.0,
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        ),
    );
  }


  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }



  void _connect() {
    if (_device == null) {
      show('No device selected');
    } else {
      bluetooth.isConnected.then((isConnected) {
        if (!isConnected) {
          bluetooth
              .connect(_device)
              .timeout(Duration(seconds: 10))
              .catchError((error) {
            setState(() => _pressed = false);
          });
          setState(() => _pressed = true);
        }
      });
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _pressed = true);
  }

  Future show(
      String message, {
        Duration duration: const Duration(seconds: 3),
      }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    _scaffoldKey.currentState.showSnackBar(
      new SnackBar(
        content: new Text(
          message,
        ),
        duration: duration,
      ),
    );
  }

  void _sendOnMessageToBluetooth() {
    print('came inside message send to bluetooth');

    bluetooth.isConnected.then((isConnected) {
      print('came inside connected method');
      if (isConnected) {
        bluetooth.write("1");
        show('Device Turned On');
      }
    });
  }


  void _sendOffMessageToBluetooth() {

    print('came iside message off to bluetooth');

    bluetooth.isConnected.then((isConnected) {
      print('came inside message off to bluetooth in is Cpnnected');
      if (isConnected) {
        bluetooth.write("0");
        show('Device Turned Off');
      }
    });

  }


}

