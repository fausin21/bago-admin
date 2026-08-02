class model_total {
  String? id;
  String? server;
  String? saldo;

  model_total({this.id, this.server, this.saldo});

  model_total.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    server = json['server'];
    saldo = json['saldo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['server'] = this.server;
    data['saldo'] = this.saldo;
    return data;
  }
}