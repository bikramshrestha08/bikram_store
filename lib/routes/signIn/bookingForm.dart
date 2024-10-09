import 'dart:convert';

import 'package:linkeat/states/app.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:linkeat/l10n/localizations.dart';
import 'package:linkeat/service/request.dart';
import 'package:linkeat/utils/SharedPreferences_util.dart';
import 'package:provider/provider.dart';

class BookingForm extends StatefulWidget {
  final String uuid;

  BookingForm({Key? key, required this.uuid}) : super(key: key);

  @override
  _BookingFormState createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';
  String _mobileNumber = '';
  String _note = '';
  int _numberOfPeople = 1;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void showInSnackBar(String value) {
    // _scaffoldKey.currentState.hideCurrentSnackBar();
    // _scaffoldKey.currentState.showSnackBar(SnackBar(
    //   content: Text(value),
    // ));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value),
    ));
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime)
      setState(() {
        _selectedTime = picked;
      });
  }

  Future<void> submitBooking(String uuid) async {
    final storeId = uuid;
    final dateString = _selectedDate.toIso8601String().split('T')[0];
    final timeString =
        "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";
    final selectdate = "${dateString}T${timeString}";
    Map<String, dynamic> body = {
      "clientName": _fullName,
      "clientContactNo": _mobileNumber,
      "numberOfPeople": _numberOfPeople,
      "clientNote": _note,
      "startTime": selectdate
    };
    final dynamic response = await Services.asyncRequest(
      'POST',
      '/store/$storeId/booking',
      context,
      payload: body,
      // }
    );
    //   const response  = 'success';
    //   var data = json.decode(response.toString());
    //   String jsonString = jsonEncode(data);
    if (response != null) {
      showInSnackBar(
        'submit successfully',
      );
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
    }
    // if (response != null && response is Map<String, dynamic>) {
    //   if (response['status'] == 'success') {
    //     showInSnackBar(
    //       'submit successfully',
    //     );
    //   } else {
    //     // Handle failure
    //   }
    // } else {
    //   // Handle the case where response is null or not a Map
    //   print('Invalid response format or null response received.');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.start, // Aligns children from the top
          children: <Widget>[
            // Company Logo and Name
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center the logo and name
              children: [
                Image.asset(
                  'images/logo.png', // Correct path to your logo
                  height: 50, // Set the height as needed
                  // Optional: Set fit to adjust how the image scales
                ),
                SizedBox(width: 10), // Space between logo and name
                Text(
                  'Bikram Store', // Replace with your company name
                  style: TextStyle(
                    fontSize: 24, // Adjust the font size as needed
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            SizedBox(height: 50), // Space below the logo and name

            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Align form items to the left
                    children: <Widget>[
                      // Date picker section
                      ListTile(
                        leading: Icon(Icons.calendar_today),
                        title: Text('${_selectedDate.toLocal()}'.split(' ')[0]),
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _selectDate(context),
                        ),
                      ),

                      // Time picker section
                      ListTile(
                        leading: Icon(Icons.access_time),
                        title: Text(_selectedTime.format(context)),
                        trailing: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _selectTime(context),
                        ),
                      ),

                      SizedBox(height: 30.0),
                      // Full Name input field
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          icon: Icon(Icons.person),
                        ),
                        onSaved: (value) {
                          _fullName = value!;
                        },
                      ),
                      SizedBox(height: 30.0), // Space between input fields

                      // Mobile Number input field
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          icon: Icon(Icons.phone),
                        ),
                        onSaved: (value) {
                          _mobileNumber = value!;
                        },
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 30.0),

                      // Number of People input field
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Number of People',
                          icon: Icon(Icons.people),
                        ),
                        initialValue: '1',
                        keyboardType: TextInputType.number,
                        onSaved: (value) {
                          _numberOfPeople = int.parse(value!);
                        },
                      ),
                      SizedBox(height: 30.0),

                      // Note input field
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Note',
                          icon: Icon(Icons.note),
                        ),
                        onSaved: (value) {
                          _note = value!;
                        },
                      ),
                      SizedBox(height: 30.0),
                    ],
                  ),
                ),
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Center(
                child: SizedBox(
                  width: 200, // Fixed width for the button
                  height: 30, // Fixed height for the button
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red, // Change the button background color
                      foregroundColor:
                          Colors.white, // Change the text color of the button
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        submitBooking(widget.uuid); // Call the submit function
                      }
                    },
                    child: Center(
                        child: Text('SUBMIT')), // Center align button text
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
