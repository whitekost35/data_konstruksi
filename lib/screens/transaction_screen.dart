import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../utils/formatters.dart';
import 'transaction_detail_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});
  @override State<TransactionScreen> createState() => _TransactionScreenState();
}
class _TransactionScreenState extends State<TransactionScreen> {
  String query=''; String? category; String? period;
  @override Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(builder:(context,p,_){
      var list=p.recentTransactions;
      if(query.isNotEmpty) list=list.where((t)=>('${t.title} ${t.note??''} ${t.category??''}').toLowerCase().contains(query.toLowerCase())).toList();
      if(category!=null) list=list.where((t)=>t.category==category).toList();
      if(period!=null) list=list.where((t)=>t.periodId==period).toList();
      return Scaffold(
        backgroundColor:Colors.transparent,
        appBar:AppBar(backgroundColor:Colors.transparent,elevation:0,title:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Daftar Transaksi',style:TextStyle(fontWeight:FontWeight.bold,fontSize:24)),Text('Tambah, edit, hapus, cari, dan ekspor seluruh transaksi',style:TextStyle(fontSize:12,color:Colors.black54))]),actions:[IconButton(onPressed:()=>showTransactionEditor(context,p),icon:const Icon(CupertinoIcons.add)),const SizedBox(width:12)]),
        body:Padding(padding:const EdgeInsets.all(24),child:Column(children:[
          Row(children:[
            Expanded(child:TextField(onChanged:(v)=>setState(()=>query=v),decoration:InputDecoration(prefixIcon:const Icon(CupertinoIcons.search),hintText:'Cari transaksi...',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)))),
            const SizedBox(width:12),
            _drop('Kategori',category,{'Bumimas_Belanja':'Bumimas_Belanja','Bumimas_Lunas':'Bumimas_Lunas','Gondes':'Gondes','Puing':'Puing','AC':'AC','Kramik':'Kramik','Lain-lain':'Lain-lain'},(v)=>setState(()=>category=v)),
            const SizedBox(width:12),
            _drop('Periode',period,{for(final x in p.periods)x.name:x.id},(v)=>setState(()=>period=v)),
            const SizedBox(width:8),
            IconButton(onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>TransactionDetailScreen(periodId:p.activePeriod?.id??'p4')),),icon:const Icon(CupertinoIcons.square_arrow_right)),
          ]),
          const SizedBox(height:16),
          Expanded(child:Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),child:ClipRRect(borderRadius:BorderRadius.circular(22),child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:DataTable(
            headingRowHeight:60,columnSpacing:28,
            columns:const[DataColumn(label:Text('Tanggal')),DataColumn(label:Text('Keterangan')),DataColumn(label:Text('Kategori')),DataColumn(label:Text('Periode')),DataColumn(label:Text('Jumlah')),DataColumn(label:Text('Aksi'))],
            rows:list.map((t)=>DataRow(cells:[
              DataCell(Text(t.date)),DataCell(Text(t.title,style:const TextStyle(fontWeight:FontWeight.w600))),DataCell(_chip(t.category??'Lain-lain')),DataCell(Text(t.periodId)),DataCell(Text(formatRupiah(t.amount),style:const TextStyle(fontWeight:FontWeight.bold))),
              DataCell(Row(children:[IconButton(onPressed:()=>showTransactionEditor(context,p,transaction:t),icon:const Icon(CupertinoIcons.pencil,size:17)),IconButton(onPressed:()=>p.deleteTransaction(t.id),icon:const Icon(CupertinoIcons.trash,size:17,color:Colors.redAccent))])),
            ])).toList(),
          )))))
        ]),),
      );
    });
  }
  Widget _drop(String hint,String? value,Map<String,String> items,ValueChanged<String?> onChanged)=>DropdownButton<String>(value:value,hint:Text(hint),items:items.entries.map((e)=>DropdownMenuItem(value:e.value,child:Text(e.key))).toList(),onChanged:onChanged);
  Widget _chip(String s){final c=s.contains('Bumimas')?Colors.blue:s=='Gondes'?Colors.deepPurple:s=='Puing'?Colors.orange:Colors.grey;return Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:c.withValues(alpha:.1),borderRadius:BorderRadius.circular(8)),child:Text(s,style:TextStyle(fontSize:11,fontWeight:FontWeight.bold,color:c)));}
}
