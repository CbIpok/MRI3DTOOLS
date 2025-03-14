function openRawFileCallback(app, serFilePath)
    % Определяем папку, в которой находится файл
    [folderPath, ~, ~] = fileparts(serFilePath);
    [~, folderName] = fileparts(folderPath);  % Имя папки используем как имя переменной
    folderName = matlab.lang.makeValidName(folderName);  % Приводим к корректному имени переменной

    % Формируем полные пути для файлов с размерностями
    fileAcqus  = fullfile(folderPath, 'acqus');
    fileAcqu2s = fullfile(folderPath, 'acqu2s');
    fileAcqu3s = fullfile(folderPath, 'acqu3s');

    % Проверяем наличие файлов с размерностями
    existsAcqus  = exist(fileAcqus, 'file') == 2;
    existsAcqu2s = exist(fileAcqu2s, 'file') == 2;
    existsAcqu3s = exist(fileAcqu3s, 'file') == 2;
    
    if ~existsAcqus && ~existsAcqu2s && ~existsAcqu3s
        errordlg('Файлы с размерностями не найдены', 'Ошибка');
        return;
    end

    % Считываем размерность по оси X из файла acqus
    if existsAcqus
        dimX = readDimensionFromFile(fileAcqus) / 2;  % делим на 2, если в файле указана общая длина данных
    else
        errordlg('Файл acqus не найден', 'Ошибка');
        return;
    end

    % Считываем размерность по оси Y из файла acqu2s (если файл отсутствует, считаем массив одномерным)
    if existsAcqu2s
        dimY = readDimensionFromFile(fileAcqu2s);
    else
        msgbox('Массив одномерный: файл acqu2s не найден', 'Информация');
        dimY = 1;
    end

    % Считываем размерность по оси Z из файла acqu3s (если отсутствует, считаем размерность равной 1)
    if existsAcqu3s
        dimZ = readDimensionFromFile(fileAcqu3s);
    else
        dimZ = 1;
    end

    % Отображаем размеры в соответствующих EditField вашего приложения
    app.XsizeEditField.Value = dimX;
    app.YsizeEditField.Value = dimY;
    app.ZsizeEditField.Value = dimZ;

    % Считываем данные из файла ser в бинарном режиме
    if exist(serFilePath, 'file') ~= 2
        errordlg('Файл ser не найден', 'Ошибка');
        return;
    end

    fid = fopen(serFilePath, 'rb');  % Открываем в бинарном режиме
    if fid == -1
        errordlg('Ошибка открытия файла ser', 'Ошибка');
        return;
    end
    dataArray = fread(fid, Inf, 'int32'); % Считываем все данные как 32-битные числа
    fclose(fid);

    if mod(length(dataArray), 2) ~= 0
        errordlg('Неверный формат данных в файле ser', 'Ошибка');
        return;
    end

    % Формируем комплексный массив
    complexData = dataArray(1:2:end) + 1i * dataArray(2:2:end);

    if numel(complexData) ~= (dimX * dimY * dimZ)
        errordlg('Размер данных не соответствует заданным размерностям', 'Ошибка');
        return;
    end

    % Преобразуем в трёхмерный массив с размерами [dimX, dimY, dimZ]
    reshapedData = reshape(complexData, [dimX, dimY, dimZ]);

    % Сохраняем массив в базовом рабочем пространстве под именем папки
    assignin('base', folderName, reshapedData);

    % Создаём структуру с информацией о файле
    rawFileStruct = struct( ...
        'filePath', serFilePath, ...               % Путь до файла
        'listName', folderName, ...                % Название для списка
        'array', reshapedData, ...                 % Считанный массив
        'dimensions', [dimX, dimY, dimZ]);          % Размерности

    % Добавляем структуру в список RawFiles
    app.RawFiles{end+1} = rawFileStruct;
    
    % Обновляем все списки (например, FilesRawListBox и FilesListBox_Array)
    updateLists(app);
end

% --- Субфункция для считывания размерности ---
function dim = readDimensionFromFile(filename)
    fid = fopen(filename, 'r');
    if fid == -1
        error(['Невозможно открыть файл: ', filename]);
    end
    dim = [];
    while ~feof(fid)
        tline = fgetl(fid);
        idx = strfind(tline, '##$TD=');
        if ~isempty(idx)
            dimStr = strtrim(tline(idx+7:end));
            dim = str2double(dimStr);
            break;
        end
    end
    fclose(fid);
    if isempty(dim) || isnan(dim)
        error(['Не удалось прочитать размерность из файла: ', filename]);
    end
end
