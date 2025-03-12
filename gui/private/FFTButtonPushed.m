function FFTButtonPushed(app)
    % Проверяем, что выбран элемент в FilesRawListBox
    if isempty(app.FilesRawListBox.Value)
        uialert(app.UIFigure, 'Выберите массив из списка FilesRawListBox.', 'Ошибка');
        return;
    end
    selectedName = app.FilesRawListBox.Value;  % имя выбранного массива
    
    % Получаем новое имя из outputnameEditField
    newName = app.outputnameEditField.;
    if isempty(newName)
        uialert(app.UIFigure, 'Введите имя для выходного массива в outputnameEditField.', 'Ошибка');
        return;
    end
    newName = matlab.lang.makeValidName(newName);  % Приводим к корректному имени переменной
    
    % Извлекаем исходный массив из базового рабочего пространства
    try
        rawArray = evalin('base', selectedName);
    catch
        uialert(app.UIFigure, sprintf('Массив с именем "%s" не найден в базовом рабочем пространстве.', selectedName), 'Ошибка');
        return;
    end
    
    if isempty(rawArray)
        uialert(app.UIFigure, 'Исходный массив пустой.', 'Ошибка');
        return;
    end

    % Применяем многомерное преобразование Фурье к массиву с центрированием спектра
    fftArray = fftshift(fftn(rawArray));
    
    % Сохраняем результат в базовом рабочем пространстве под новым именем
    assignin('base', newName, fftArray);
    


    % Создаем структуру для FFT массива
    fftStruct = struct('filePath', '', ...         % Для FFT можно не хранить путь
                       'listName', newName, ...
                       'array', fftArray, ...
                       'dimensions', size(fftArray));
    app.FFTArrays{end+1} = fftStruct;
    
    % Обновляем все списки через универсальную функцию updateLists
    updateLists(app);
    
    % Визуализируем спектр: если массив 3D, показываем центральный срез по оси z, иначе весь массив
    figure;
    dims = size(fftArray);
    if numel(dims) >= 3 && dims(3) > 1
        slice_index = ceil(dims(3)/2);
        imagesc(abs(fftArray(:,:,3)));
    else
        imagesc(abs(fftArray));
    end
    colorbar;
    axis image;
end
