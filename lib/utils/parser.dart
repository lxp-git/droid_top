void parseLine(_result, _name, _line) {
  var line = _line.replace(RegExp("%"), "").split(":")[1].replace(RegExp(" "), "");
  _result[_name] = {};
  var line_items = line.split(",");

  for (var i = 0, item = line_items[i]; i < line_items.length; item = line_items[++i]) {
    var value = double.parse(item);
    if (value == 0 && item.indexOf(".") != -1) {
      value = 0.0;
    }
    var name = item.replace(value, "").replace(".0", "");
    _result[_name][name] = value;
  } //for
} //parseLine

void parseProces(_result, _line) {
  var items = _line.split(",");
  var processes = {"pid": items[0], "user": items[1], "pr": items[2], "ni": items[3], "virt": items[4], "res": items[5], "shr": items[6], "s": items[7], "cpu": items[8], "mem": items[9], "time": items[10], "command": items[11]};
  _result.processes.push(processes);
} //parseProces

dynamic parseTopOutput(data, {pid_limit}) {
  print("data");
  print(data);
  if (data.toString().isEmpty) {
    return;
  }
  Map<String, dynamic> result = {"processes": []};
  var data_line = data.split("\n");
  //sys info
  //parseLine("top",data_line[0])
  parseLine(result, "task", data_line[1]);
  parseLine(result, "cpu", data_line[2].replace(" us,", "user,").replace(" sy,", " system,").replace(" id,", " idle,"));
  //console.dir(data_line[2])
  //console.dir(data_line[3])
  parseLine(result, "ram", data_line[3].replace(RegExp("k "), " "));
  parseLine(result, "swap", data_line[4].replace("free.", "free,"));

  //process
  if (pid_limit) {
    if (pid_limit >= data_line.length - 1) {
      pid_limit = data_line.length - 1;
    } else {
      pid_limit += 7;
    }
  } //if pid_limit
  else {
    pid_limit = data_line.length - 1;
  }
  for (var i = 7, item = data_line[i]; i < pid_limit; item = data_line[++i]) {
    if (item) {
      var line = item.replace(RegExp("/\s{1,}/g"), ',').substring(1);
      if (line != "") {
        parseProces(result, line);
      } //if
    } //if item
  } //for process
  result["time"] = DateTime.now().microsecondsSinceEpoch;

  return result;
}

final pidStart = 0;
final pidEnd = "  PID ".length;
final userEnd = "  PID USER         ".length;
final cpuStart = "  PID USER         PR  NI VIRT  RES  SHR S".length;
final cpuEnd = "  PID USER         PR  NI VIRT  RES  SHR S[%CPU]".length;
final memoryStart = cpuEnd;
final memoryEnd = "  PID USER         PR  NI VIRT  RES  SHR S[%CPU] %MEM".length;
final nameStart = "  PID USER         PR  NI VIRT  RES  SHR S[%CPU] %MEM     TIME+ ".length;
