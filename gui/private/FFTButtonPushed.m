function FFTButtonPushed(app)
    % Проверяем, что выбран элемент в FilesListBox
    if isempty(app.FilesListBox.Value)
        uialert(app.UIFigure, 'Выберите массив из списка FilesListBox.', 'Ошибка');
        return;
    end
    selectedName = app.FilesListBox.Value;  % имя выбранного массива
    
    % Получаем новое имя из outputnameEditField
    newName = app.outputnameEditField.Value;
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
    
    % Обновляем список доступных FFT-массивов в FilesListBox_Array
    if isprop(app.FilesListBox_Array, 'Items')
        if isempty(app.FilesListBox_Array.Items)
            app.FilesListBox_Array.Items = {newName};
        else
            app.FilesListBox_Array.Items{end+1} = newName;
        end
    else
        warning('FilesListBox_Array не имеет свойства Items.');
    end
    
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
