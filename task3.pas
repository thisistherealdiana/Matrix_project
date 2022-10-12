{$IFDEF WINDOWS}
     {$APPTYPE CONSOLE}
{$ENDIF}

uses
     {$IFDEF UNIX}
       {$IFDEF UseCThreads}
       cthreads,
         {$ENDIF}
       {Widestring manager needed for widestring support}
       cwstring,
       {$ENDIF}
       {$IFDEF WINDOWS}
       Windows, {for setconsoleoutputcp}
       {$ENDIF}
       Classes,
       math;
       
type 
  tree = ^node;
  node = record
    node_number, row, column, i : integer;
    number : double;
    left, right, parent : tree;
end;

var 
  mode, i : integer; 
  _name : string;
  _file, index : text;
  matrix_1, matrix_2 : tree;
  
function Coord_less(row_1, column_1, row_2, column_2 : integer) : boolean;
begin
  Coord_less := (row_1 < row_2) or 
  (row_1 = row_2) and (column_1 < column_2)
end;

{поиск элемента в дереве}
function Find_element(row, column : integer; node : tree) : double;
begin
  if Coord_less(row, column, node^.row, node^.column) then
    if node^.left <> nil 
      then Find_element := Find_element(row, column, node^.left) 
      else Find_element := 0
    else if (row = node^.row) and (column = node^.column) 
        then Find_element := node^.number
        else if node^.right <> nil
          then Find_element := Find_element(row, column, node^.right)
          else Find_element := 0
end;

procedure Plus_main_node(matrix : tree; flag : boolean);
begin
  if matrix <> nil then
  begin
    if flag
      then matrix^.node_number := matrix^.node_number + 1
      else matrix^.node_number := matrix^.node_number - 1;
    Plus_main_node(matrix^.left, flag);
    Plus_main_node(matrix^.right, flag)
  end
end;

{правый поворот балансировка}
procedure Right_turn(main_node : tree);
begin
  main_node^.node_number := main_node^.node_number + 1;
  main_node^.left^.node_number := main_node^.left^.node_number - 1;
  if main_node^.left^.left <> nil then
    Plus_main_node(main_node^.left^.left, false);
  if main_node^.right <> nil then
    Plus_main_node(main_node^.right, true);
  if main_node = main_node^.parent^.left
    then main_node^.parent^.left := main_node^.left
    else main_node^.parent^.right := main_node^.left;
  main_node^.left^.parent := main_node^.parent;
  main_node^.parent := main_node^.left;
  main_node^.left := main_node^.left^.right;
  if main_node^.left <> nil then
    main_node^.left^.parent := main_node;
  main_node^.parent^.right := main_node;
end;

{левый поворот балансировка}
procedure Left_turn(main_node : tree);
begin
  main_node^.node_number := main_node^.node_number + 1;
  main_node^.right^.node_number := main_node^.right^.node_number - 1;
  if main_node^.right^.right <> nil then
    Plus_main_node(main_node^.right^.right, false);
  if main_node^.left <> nil then
    Plus_main_node(main_node^.left, true);
  if main_node = main_node^.parent^.left
    then main_node^.parent^.left := main_node^.right
    else main_node^.parent^.right := main_node^.right;   
  main_node^.right^.parent := main_node^.parent;
  main_node^.parent := main_node^.right;
  main_node^.right := main_node^.right^.left;
  if main_node^.right <> nil then
    main_node^.right^.parent := main_node;  
  main_node^.parent^.left := main_node
end;
  
{высота узла}
function Height(node : tree) : integer;
var
  i, j : integer;
begin
  Height := 0;
  if node <> nil then 
  begin
    i := Height(node^.left);
    j := Height(node^.right);
    Height := i + 1;
    if j > i then 
      Height := j + 1
  end
end;

{балансировка}
procedure Balance(element : tree);
var
  node : tree;
  _Height : integer;
  left_child, left_subtree : boolean;
begin
  node := element;
  repeat
    node := node^.parent;
    _Height := Height(node^.left) - Height(node^.right) {коэффициент сбалансированности}
  until (abs(_Height) > 1) or (node^.node_number = 1);
  if abs(_Height) > 1 then 
  begin
    left_child := 
    Coord_less(element^.row, element^.column, node^.row, node^.column);
    if left_child 
      then node := node^.left 
      else node := node^.right;
    left_subtree := 
    Coord_less(element^.row, element^.column, node^.row, node^.column);
    node := node^.parent;
    if left_child then 
      if left_subtree 
      then Right_turn(node) 
      else begin
        Left_turn(node^.left);
        Right_turn(node)
      end
    else if left_subtree then
      begin
        Right_turn(node^.right);
        Left_turn(node)
      end
      else Left_turn(node)
  end;
end;
  
procedure Add_node(element, node : tree);
begin
  if Coord_less(element^.row, element^.column, node^.row, node^.column) then
    if node^.left <> nil
      then Add_node(element, node^.left)
      else 
      begin
        node^.left := element;
        element^.parent := node;
        element^.node_number := node^.node_number + 1;
        Balance(element)
      end 
    else if node^.right <> nil
      then Add_node(element, node^.right) 
      else 
      begin
        node^.right := element;
        element^.parent := node;
        element^.node_number := node^.node_number + 1;
        Balance(element);
      end
end;

procedure Print_file(var _file : text; matrix : tree);
begin
  if matrix <> nil then 
  begin
    Print_file(_file, matrix^.left);
    writeln(_file, matrix^.row, '  ', matrix^.column, '  ', matrix^.number:5:3);
    Print_file(_file, matrix^.right)
  end
end;

procedure Dispose_matrix(matrix : tree);
begin
  if matrix <> nil then
  begin
    Dispose_matrix(matrix^.left);
    Dispose_matrix(matrix^.right);
    dispose(matrix)
  end
end;

procedure Generator();                                                        
var
    i, m, n, mode, row, column, num_nonzero_elements: integer;
    density : real;
    error : boolean;
    file_name : string;
    matrix, element : tree;
    matrix_file : text;
begin
  {$I-}
  error := false;
  repeat 
    if error then 
      writeln('Неверный ввод');
    writeln('Enter the amount of rows');
    read(row);
    error := (row <= 0)
  until not error;
  repeat
    if error then 
      writeln('Incorrect input');
    writeln('Enter the amount of columns');
    read(column);
    error := (column <= 0)
  until not error;
  repeat
    if error then 
      writeln('Incorrect input');
    writeln('Enter the sparsity value');
    read(density);
    error := (density <= 0) or (density > 1)
  until not error;
  repeat
    if error then 
      writeln('Incorrect input');
    writeln('Choose: 1 - filled with units, 2 - filled with random values, 3 - identity matrix');
    read(mode);
    error := (mode < 1) or (mode > 3)
  until not error;
  new(matrix);
  matrix^.node_number := 0;
  matrix^.right := nil;
  new(matrix^.left);
  matrix^.left^.parent := matrix;
  matrix^.left^.node_number := 1;
  matrix^.left^.left := nil;
  matrix^.left^.right := nil;
  if mode = 3 then 
  begin
    matrix^.left^.row := 1;
    matrix^.left^.column := 1;
    matrix^.left^.number := 1;
    m := row;
    if row > column then m := column;
    for i := 2 to m do begin
      new(element);
      element^.row := i;
      element^.column := i; 
      element^.number := 1;
      element^.left := nil;
      element^.right := nil;
      Add_node(element, matrix^.left)
    end
  end else 
  begin
    matrix^.left^.row := random(row) + 1;
    matrix^.left^.column := random(column) + 1;
    if mode = 1
      then matrix^.left^.number := 1
      else if mode = 2 
        then matrix^.left^.number := 1000 * random * (random(2) * 2 - 1)
        else matrix^.left^.number := random(9) + 1;
    num_nonzero_elements := trunc(row * column * density);
    if num_nonzero_elements = 0 then num_nonzero_elements := 1;
    for i := 2 to num_nonzero_elements do 
    begin
      new(element);
      repeat
		m:= random(row) + 1;
        n:= random(column) + 1;
      until Find_element(m, n, matrix^.left) = 0;
      element^.row := m;
      element^.column := n;
      element^.left := nil;
      element^.right := nil;
      if mode = 1
        then element^.number := 1
        else if mode = 2
          then element^.number := 1000 * random * (random(2) * 2 - 1)
          else element^.number := random(9) + 1;
      Add_node(element, matrix^.left)
    end  
  end;
  writeln('Do you want to print the matrix?');
  repeat
    readln(file_name)
  until (file_name = 'yes') or (file_name = 'no');
  if file_name = 'yes' then
    for i := 1 to row do
    begin
      for m := 1 to column do
      begin
        write(Find_element(i, m, matrix^.left));
        write(' ')
      end;
      writeln
    end;
  writeln('Enter the file name');
  readln(file_name);
  Assign(matrix_file, file_name);
  rewrite(matrix_file);
  write(matrix_file, 'matrix  ');
  write(matrix_file, row);
  write(matrix_file, '  ');
  writeln(matrix_file, column);
  Print_file(matrix_file, matrix^.left);
  Close(matrix_file);
  Dispose_matrix(matrix)
end;


function Convert_file_to_matrix(var _text : text) : tree;
var
  matrix, element : tree;
  symbol : char;
  i, row, column: integer;
  number : double; {длина 8}
  _string : string;
  
  function Read_string(var row, column : integer; var number : double) : integer;
  var
    symbol : char;
  begin
    Read_string := 0;
    repeat
      read(_text, symbol)
    until (ord(symbol) <> 10) and (symbol <> ' ') and (ord(symbol) <> 13) or 
    eoln(_text);
    if not eoln(_text) then
    begin
      if symbol = '#'
        then Read_string := 2
        else if (ord(symbol) <= ord('9')) and (ord(symbol) >= ord('0')) then
        begin
          row := ord(symbol) - ord('0');
          repeat
            read(_text, symbol);
            if (ord(symbol) >= ord('0')) and (ord(symbol) <= ord('9')) then 
            begin
              row := row * 10;
              row := row + ord(symbol) - ord('0')
            end 
          until eoln(_text) or 
          (ord(symbol) < ord('0')) or (ord(symbol) > ord('9'));
          read(_text, symbol);
          if (symbol = ' ') or (ord(symbol) = 10) or (ord(symbol) = 13) then    
          begin
            read(_text, column);
            if not eoln(_text) then
            begin
              read(_text, number);
                Read_string := 1;
                while not eoln(_text) do
                begin
                  read(_text, symbol);
                  if (ord(symbol) <> 10) and (symbol <> ' ') and (ord(symbol) <> 13) then{}
                    Read_string := 0
                end;
                readln(_text);
            end
          end
        end
    end
    else if (ord(symbol) = 10) or (symbol = ' ') or (ord(symbol) = 13)
      then Read_string := 2;
  end;

begin
  Convert_file_to_matrix := nil;
  Reset(_text);
  if not eof(_text) then 
  begin
    repeat
      read(_text, symbol);
      if symbol = '#' then 
        if not eof(_text) then
          readln(_text);
    until (ord(symbol) <> 10) and (ord(symbol) <> 13) and (symbol <> ' ') or (symbol <> '#') or eof(_text);
    _string := symbol;
    for i := 1 to 5 do 
      if not eoln(_text) then
      begin
        read(_text, symbol);
        _string := _string + symbol 
      end;
    if _string = 'matrix' then
      if not eoln(_text) then
      begin
        repeat
          read(_text, symbol)
        until eoln(_text) or (symbol <> ' ') and (ord(symbol) <> 10) and (ord(symbol) <> 13);{}
        if (ord(symbol) >= ord('0')) and (ord(symbol) <= ord('9')) then
        begin
          row := ord(symbol) - ord('0');
          repeat
            read(_text, symbol);
            if (ord(symbol) >= ord('0')) and (ord(symbol) <= ord('9')) then 
              row := row * 10  + ord(symbol) - ord('0');
          until eoln(_text) or 
          (ord(symbol) < ord('0')) or (ord(symbol) > ord('9'));
          if symbol = ' ' then 
          begin
            if not eoln(_text) then
            begin
              repeat
                read(_text, symbol)
              until eoln(_text) or (symbol <> ' ') and (ord(symbol) <> 10) and (ord(symbol) <> 13);{}
              if (ord(symbol) >= ord('0')) and (ord(symbol) <= ord('9')) then
              begin
                column := ord(symbol) - ord('0');
                repeat
                  read(_text, symbol);
                  if (ord(symbol) >= ord('0')) and (ord(symbol) <= ord('9'))then 
                    column := column * 10 + ord(symbol) - ord('0');
                until eoln(_text) or 
                (ord(symbol) < ord('0')) or (ord(symbol) > ord('9'));
                readln(_text);
                if (not eof(_text)) and (row > 0) and (column > 0) then
                begin
                  new(matrix);
                  matrix^.row := row;
                  matrix^.column := column;
                  matrix^.node_number := 0;
                  repeat
                    i := Read_string(row, column, number)
                  until eof(_text) or (i = 1) or (i = 0);
                  if eof(_text) or (i <> 1) or not((row > 0) and (column > 0) 
                  and (row <= matrix^.row) and (column <= matrix^.column))
                    then dispose(matrix)
                    else
                    begin
                      Convert_file_to_matrix := matrix;
                      new(matrix^.left);
                      matrix^.left^.row := row;
                      matrix^.left^.column := column;
                      matrix^.left^.number := number;
                      matrix^.left^.node_number := 1;
                      matrix^.left^.parent := matrix;
                      matrix^.left^.left := nil;
                      matrix^.left^.right := nil;
                      while not eof(_text) do begin
                        i := Read_string(row, column, number);
                        if (i = 1) and (row > 0) and (column > 0) and 
                        (row <= matrix^.row) and (column <= matrix^.column) then
                          begin
                            new(element);
                            element^.row := row;
                            element^.column := column;
                            element^.number := number;
                            element^.left := nil;
                            element^.right := nil;
                            Add_node(element, matrix^.left)
                          end else
                            if i = 0 then
                            begin
                              Convert_file_to_matrix := nil;
                              dispose(matrix^.left);
                              dispose(matrix)
                            end
                      end
                    end
                  
                end
              end
            end        
          end
        end
      end  
  end;
  Close(_text)
end;  

function Convert_index_to_matrix(var _text : text) : tree;
var
  _string : string;
  symbol : char;
  row, column, i : integer;
  number : double;
  first : boolean;
  element, matrix : tree;
  
  function Read_string(var row, column : integer; var number : double) : integer;
  var
    i : integer;
  begin
    Read_string := 2;
    _string := '';
    repeat
      read(_text, symbol)
    until ((symbol <> ' ') and (ord(symbol) <> 13) and (ord(symbol) <> 10)) or
    eoln(_text);
    if (not eoln(_text)) then
      if symbol = '/' then
      begin
        Read_string := 0;
        for i := 1 to 6 do
          if not eoln(_text) then
          begin
            read(_text, symbol);
            _string := _string + symbol;
          end;
        if (_string = '/edges') and (Read_string(row, column, number)  = 2) then
          Read_string := 3;
      end else
      begin
        Read_string := 0;
        if (ord(symbol) <= 9) or (ord(symbol) >= 0)  and (not eoln(_text)) then
        begin
          repeat
            read(_text, symbol)
          until not ((ord(symbol) <= 9) and (ord(symbol) >= 0)) or eoln(_text);
          if ((ord(symbol) = 13) or (ord(symbol) = 10) or (ord(symbol) = 32)) 
          and not eoln(_text) then
          begin
            repeat
              read(_text, symbol)
            until ((symbol <> ' ') and (ord(symbol) <> 13) and 
            (ord(symbol) <> 10)) or eoln(_text);
            _string := symbol;
            for i := 1 to 7 do
              if not eof(_text) then
              begin
                read(_text, symbol);
                _string := _string + symbol;
              end;
            if _string = '[label="' then
            begin
              read(_text, row);
                repeat
                  read(_text, symbol)
                until ((symbol <> ' ') and (ord(symbol) <> 13) and 
                (ord(symbol) <> 10)); 
                if (ord(symbol) <= ord('9')) and (ord(symbol) >= ord('0')) then
                begin
                  column := ord(symbol) - ord('0');
                  repeat
                    read(_text, symbol);
                    if (ord(symbol) <= ord('9')) and (ord(symbol) >= ord('0'))
                      then column := row * 10 + ord(symbol) - ord('0');
                  until (ord(symbol) > ord('9')) or (ord(symbol) < ord('0'));
                  if (symbol = '\') and not eof(_text) then
                  begin
                    read(_text, symbol);
                    if symbol = 'n' then 
                    begin
                      read(_text, number);
                        Read_string := 1;
                    end
                  end
                end
            end
          end
        end
      end;
    readln(_text);
  end;
  
begin
Convert_index_to_matrix := nil;
first := true;
Reset(_text);
_string := '';
for i:= 1 to 7 do
  if not eof(_text) then
  begin
    read(_text, symbol);
    _string := _string + symbol
  end;
  if (_string = 'digraph') and (Read_string(row, column, number) = 2) and not eoln(_text) then
  begin
    read(_text, symbol);
    if (symbol = '{') and (Read_string(row, column, number) = 2) and not eoln(_text) then
    begin
      repeat
        i := Read_string(row, column, number); 
        if i = 1 then
          if first then
          begin
            new(matrix);
            matrix^.node_number := 0;
            new(matrix^.left);
            matrix^.left^.row := row;
            matrix^.left^.column := column;
            matrix^.left^.number := number;
            matrix^.left^.node_number := 1;
            matrix^.left^.parent := matrix;
            matrix^.left^.left := nil;
            matrix^.left^.right := nil;
            first := false;
          end else
          begin
            new(element);
            element^.row := row;
            element^.column := column;
            element^.number := number;
            element^.left := nil;
            element^.right := nil;
            Add_node(element, matrix^.left)
          end;
      until (i = 0) or (i = 3) or eof(_text); ;
      if i = 3 
        then Convert_index_to_matrix := matrix;
    end
  end;
Close(_text);
end;
    
procedure Built_index(var _file, index : text);
var
  matrix : tree;
  i : integer;
  
  procedure Print_nodes(matrix : tree; var i : integer);
  begin
    if matrix <> nil then
    begin
      i := i + 1;
      writeln(index, i, ' [label="', matrix^.row, '   ', matrix^.column, '\n', 
      matrix^.number:5:3, ' "];');
      matrix^.node_number := i;
      Print_nodes(matrix^.left, i);
      Print_nodes(matrix^.right, i)
    end
  end;
  
  procedure Print_edges(matrix : tree);
  begin
    if matrix <> nil then
    begin
      if matrix^.left <> nil then
        write(index, matrix^.node_number, ' -> ', matrix^.left^.node_number,
        ' [label="L"]; ');
      if matrix^.right <> nil then
        writeln(index, matrix^.node_number, ' -> ', matrix^.right^.node_number,
        ' [label="R"]; ');
      Print_edges(matrix^.left);
      Print_edges(matrix^.right)
    end
  end;
  
begin
  matrix := Convert_file_to_matrix(_file);
  if matrix <> nil then
  begin
    i := 0;
    Rewrite(index);
    writeln(index, 'digraph');
    writeln(index, '{');
    Print_nodes(matrix^.left, i);
    writeln(index, '//edges');
    Print_edges(matrix^.left);
    writeln(index, '}');
    Close(index);
    Dispose_matrix(matrix)
  end else writeln('Incorrect file')
end;

procedure Multiplier(matrix_1, matrix_2 : tree);
var
  _file, index : text;
  file_name : string;
  matrix_3, element : tree;
  epsilon, number : double;
  error, first : boolean;
  i, j, k : integer;
begin
  writeln('Enter the name of output file');
  readln(file_name);
  error := false;
  repeat
    if error then 
      writeln('Invalid input');
    writeln('Enter the value of epsilon');
    read(epsilon);
    error := (epsilon < 0);
  until not error;
  if matrix_1^.column = matrix_2^.row then
  begin
    first := true;
    Assign(_file, file_name);
    new(matrix_3);
    matrix_3^.left := nil;
    matrix_3^.node_number := 0;
    for i := 1 to matrix_1^.row do 
      for j := 1 to matrix_2^.column do 
      begin
        number := 0;
        for k := 1 to matrix_2^.row do
          number := number + 
          Find_element(i,k,matrix_1^.left) * Find_element(k,j,matrix_2^.left);
        if ((number >= epsilon)or(number <= -epsilon))and (number <> 0) then
          if first then
          begin
            new(matrix_3^.left);
            matrix_3^.left^.left := nil;
            matrix_3^.left^.right := nil;
            matrix_3^.left^.number := number;
            matrix_3^.left^.parent := matrix_3;
            matrix_3^.left^.node_number := 1;
            matrix_3^.left^.row := i;
            matrix_3^.left^.column := j;
            first := false
          end else 
          begin
            new(element);
            element^.left := nil;
            element^.right := nil;
            element^.number := number;
            element^.row := i;
            element^.column := j;
            Add_node(element, matrix_3^.left)
          end
      end;
    rewrite(_file);
    write(_file, 'matrix  ');
    write(_file, matrix_1^.row);
    write(_file, '  ');
    writeln(_file, matrix_2^.column);
    Print_file(_file, matrix_3^.left);
    Close(_file);
    writeln('Do you want to generate index?');
    repeat
      readln(file_name)
    until (file_name = 'yes') or (file_name = 'no');
    if file_name = 'yes' then
    begin
      writeln('Enter the index file');
      readln(file_name);
      Assign(index, file_name);
      Built_index(_file, index)
    end;
    Dispose_matrix(matrix_3)
  end else writeln('Incorrect matrix size');
end;

procedure Print_index(matrix : tree);
begin
  if matrix <> nil then
  begin
    write(matrix^.number, ' ');
    if (matrix^.left <> nil) or (matrix^.right <> nil)
      then writeln( matrix^.node_number)
      else writeln('NULL');
    Print_index(matrix^.left);
    Print_index(matrix^.right);
  end;
end;

procedure Print_index_2(matrix : tree; i :integer);
begin
  if matrix <> nil then
  begin
    if matrix^.node_number = i then
      writeln(matrix^.number);
    if matrix^.node_number < i then
    begin
      Print_index_2(matrix^.left, i);
      Print_index_2(matrix^.right, i)
    end
  end
end;

{основная программа}
begin
  {$I-}    
  repeat
    writeln('Choose: 1 - generator, 2 - multiplier');
    writeln('3 - index builder, 4 -  index mapper, 5 - exit');
    repeat
     read(mode)
    until (mode >= 1) and (mode <= 5);
    if mode = 1 then Generator();
    if mode = 2 then 
    begin
      writeln('file or index?');
      repeat
        readln(_name)
      until (_name = 'file') or (_name = 'index');
      if _name = 'file' then
      begin
        writeln('Enter the name of the file with first matrix');
        readln(_name);
        Assign(_file, _name);
        matrix_1 := Convert_file_to_matrix(_file);
        if matrix_1 <> nil then 
        begin
          writeln('Enter the name of the file with second matrix');
          readln(_name);
          Assign(_file, _name);
          matrix_2 := Convert_file_to_matrix(_file);
          if matrix_2 <> nil then 
            begin
              Multiplier(matrix_1, matrix_2);
              Dispose_matrix(matrix_2)
            end else writeln('Incorrect file');
          Dispose_matrix(matrix_1)
        end else writeln('Incorrect file');
      end else
      begin
        writeln('Enter the name of the first file with indexes');
        readln(_name);
        Assign(_file, _name);
        matrix_1 := Convert_index_to_matrix(_file);
        if matrix_1 <> nil then 
        begin
          writeln('Enter the name of the second file with indexes');
          readln(_name);
          Assign(_file, _name);
          matrix_2 := Convert_index_to_matrix(_file);
          if matrix_2 <> nil
            then
            begin
              writeln('Enter the amount of rows in the first index file');
              readln(matrix_1^.row);
                writeln('Enter the amount of columns in the first index file');
                readln(matrix_1^.column);
                  writeln('Enter the amount of rows вin the second index file');
                  readln(matrix_2^.row);
                    writeln('Enter the amount of columns in the second index file');
                    readln(matrix_2^.column);
                    Multiplier(matrix_1, matrix_2);
              Dispose_matrix(matrix_2)
            end else writeln('Incorrect file');
            Dispose_matrix(matrix_1);
        end else writeln('Incorrect file');
      end
    end;
    if mode = 3 then 
    begin
      writeln('Enter the name of the matrix file');
      readln;
      readln(_name);
      Assign(_file, _name);
      writeln('Enter the name of the index file');
      readln(_name);
      Assign(index, _name);
      Built_index(_file, index)
    end;
    if mode = 4 then
    begin 
      writeln('Enter the name of the file with indexes');
      readln;
      readln(_name);
      Assign(_file, _name);
      matrix_1 := Convert_index_to_matrix(_file);
      if matrix_1 <> nil then
      begin
        writeln('Choose: 1 - three is printed as: root, then left subtree, then right subtree.');
        writeln('2 - tree is printed by levels: from root to leaves');
        repeat
          readln(mode);
        until (mode = 1) or (mode = 2); 
        if mode = 1 
          then 
            Print_index(matrix_1^.left)
          else 
            for i := 1 to Height(matrix_1^.left) do
              Print_index_2(matrix_1^.left, i);
      end else writeln('Incorrect file');
      Dispose_matrix(matrix_1)
    end
  until mode = 5
end. 
