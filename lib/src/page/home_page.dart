import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:band_names/src/services/socket_service.dart';
import 'package:band_names/src/models/band.dart';


class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Band> bands = [
    // Band( id: '1', name: 'Metallica', votes: 5),
    // Band( id: '2', name: 'Queen', votes: 10),
    // Band( id: '3', name: 'Heroes del silencio', votes: 3),
    // Band( id: '4', name: 'Bon Jovi', votes: 4),
  ];

  @override
  void initState() {
    
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands',  _handleActiveBands );
    super.initState();
  }

  _handleActiveBands( dynamic payload ) {

    this.bands = (payload as List).map((band) => Band.fromMap(band)).toList();

      setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('BandNames', style: TextStyle(color: Colors.black87),),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 10),
            child: ( socketService.serverStatus == ServerStatus.Online )
            ?Icon(Icons.check_circle, color: Colors.blue[300])
            :Icon(Icons.offline_bolt, color: Colors.red),
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          _showGraph(),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: (BuildContext context, int index)=> _bandTile( bands[index] )
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        elevation: 1,
        onPressed: addNewBand,
      ),
   );
  }

  Widget _bandTile(Band band) {

    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
        key: Key(band.id),
        direction: DismissDirection.startToEnd,
        onDismissed: ( _ ) => socketService.socket.emit('delete-band', { 'id': band.id } ),
        background: Container(
          padding: EdgeInsets.only( left: 8.0 ),
          color: Colors.red,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Delete Band', style: TextStyle(color: Colors.white, fontSize: 20),),
          ),
        ),
        child: ListTile(
        leading: CircleAvatar(
          child: Text( band.name.substring(0,2)),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(band.name),
        trailing: Text('${ band.votes }', style: TextStyle(fontSize: 20),),
        onTap: () => socketService.socket.emit('vote-band', { 'id': band.id } ),
      ),
    );
  }

  addNewBand() {
    
    final textController = new TextEditingController();

    if( Platform.isAndroid ) {
      return showDialog(
        context: context,
        builder: ( _ ) => AlertDialog(
            title: Text('New band name:'),
            content: TextField(
              controller: textController,
            ),
            actions: <Widget>[
              MaterialButton(
                child: Text('Add'),
                elevation: 5,
                textColor: Colors.blue,
                onPressed: ()=> addBandToList( textController.text ),
              )
            ],
          )
      );
    }

    showCupertinoDialog(
      context: context, 
      builder: ( _ ) {
        return CupertinoAlertDialog(
          title: Text('New band name'),
          content: CupertinoTextField(
            controller: textController,
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Add'),
              onPressed: ()=> addBandToList( textController.text ),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Dismiss'),
              onPressed: ()=> Navigator.pop(context),
            ),
          ],
        );
      }
    );
    
  }

  void addBandToList( String name ) {

    

    if (name.length > 1 ) {
      // podemos agregar
      final socketService = Provider.of<SocketService>(context, listen: false);
      
      socketService.socket.emit('add-band', { 'name' : name } );
      
    }

    Navigator.pop(context);
  }

  // Mostrar grafica
  Widget _showGraph() {

    Map<String, double> dataMap = new Map();
      // dataMap.putIfAbsent("Flutter", () => 5);
      bands.forEach((band) { 
        dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
      });
      

      return Container(
        width: double.infinity,
        height: 200,
        child: PieChart(dataMap: dataMap)
      );
  }
  
}