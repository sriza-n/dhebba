import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'dart:typed_data';
import 'package:nfc_host_card_emulation/nfc_host_card_emulation.dart';

class NfcPage extends NyStatefulWidget {
  static const path = '/nfc';

  NfcPage({super.key}) : super(path, child: _NfcPageState());
}

class _NfcPageState extends NyState<NfcPage> with TickerProviderStateMixin {
  late NfcState _nfcState;
  late List<int> paydata;
  final port = 0;
  bool apduAdded = false;
  NfcApduCommand? nfcApduCommand;

  @override
  boot() async {
    _nfcState = await NfcHce.checkDeviceNfcState();

    if (_nfcState == NfcState.enabled) {
      await NfcHce.init(
        // AID that match at least one aid-filter in apduservice.xml
        // In my case it is A000DADADADADA.
        aid: Uint8List.fromList([0xF0, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06]),
        // next parameter determines whether APDU responses from the ports
        // on which the connection occurred will be deleted.
        // If `true`, responses will be deleted, otherwise won't.
        permanentApduResponses: true,
        // next parameter determines whether APDU commands received on ports
        // to which there are no responses will be added to the stream.
        // If `true`, command won't be added, otherwise will.
        listenOnlyConfiguredPorts: false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // portController.text = port.toString();
    // // Simulate NFC enabled state for UI testing
    // Future.delayed(Duration.zero, () {
    //   setState(() {
    //     _nfcState = NfcState.enabled;
    //   });
    // });
    initUserPhone();
    NfcHce.stream.listen((command) {
      setState(() => nfcApduCommand = command);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initUserPhone() async {
    final userphone = await NyStorage.read("userphone");
    print(userphone);
    paydata = userphone.toString().split('').map(int.parse).toList();
    print(paydata);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _nfcState == NfcState.enabled
          ? Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'NFC State is ${_nfcState.name}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  SizedBox(
                    height: 200,
                    width: 300,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          apduAdded
                              ? Color.fromARGB(255, 0, 0, 0)
                              : Color.fromARGB(255, 255, 255, 255),
                        ),
                        shape: WidgetStateProperty.all(CircleBorder()),
                      ),
                      onPressed: null,
                      onLongPress: () async {
                        if (apduAdded == false) {
                          await NfcHce.addApduResponse(port, paydata);
                        } else {
                          await NfcHce.removeApduResponse(port);
                        }

                        setState(() => apduAdded = !apduAdded);
                      },
                      child: FittedBox(
                        child: Text(
                          apduAdded ? 'release' : 'push to pay',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            color: apduAdded ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (nfcApduCommand != null)
                    Text(
                      // 'You listened to the stream and received the '
                      // 'following command on the port ${nfcApduCommand!.port}:\n'
                      // '${nfcApduCommand!.command}\n'
                      // 'with additional data ${nfcApduCommand!.data}',
                      'Scan succesful\n${nfcApduCommand!.command}',
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            )
          : Center(
              child: Text(
                'Oh no...\nNFC is ${_nfcState.name}',
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}
