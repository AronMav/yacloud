#Использовать xml-parser
#Использовать logos

Перем Лог;

// Формирует текст команды для создания ВМ
//
// Параметры:
//   ИмяВиртуальнойМашины - Имя виртуальной машины
//	 ПараметрыВМ - Строка - Путь к файлу параметров
//
// Возвращаемое значение:
//   Строка - Команда для создания ВМ
//
Функция СформироватьКомандуСозданияВМ(ИмяВиртуальнойМашины, ПараметрыВМ) Экспорт
	КаталогБиблиотек = ОбъединитьПути(КаталогПрограммы(), ПолучитьЗначениеСистемнойНастройки("lib.system"));
	ПутьКФайлу = КаталогБиблиотек + "/yacloud/src/arguments.xml";
	ПроцессорXML = Новый СериализацияДанныхXML();
	РезультатЧтения = ПроцессорXML.ПрочитатьИзФайла(ПутьКФайлу)["YC"];
	Команда = СтрШаблон("yc compute instance create --no-user-output --format json --name %1", ИмяВиртуальнойМашины);
	ПараметрыКоманды = ПараметрыИзФайлаВКоманду(ПараметрыВМ, РезультатЧтения["Параметры"], РезультатЧтения["Зависимости"]);
	Команда = Команда + ПараметрыКоманды;
	
	Возврат СокрЛП(Команда);
КонецФункции

// Формирует текст команды для создания ВМ из Файла
//
// Параметры:
//	 ПараметрыВМ - Строка - Путь к файлу с параметрами ВМ
//	 ЭлементыXML - Соответствие - Прочитанный arguments.xml область Параметры
//	 Зависимости - Соответствие - Прочитанный arguments.xml область Зависимости
//	 Разделитель - Строка - Строковое представление разделителя
//
// Возвращаемое значение:
//   Строка - Параметры исполняемой команды
//
Функция ПараметрыИзФайлаВКоманду(Знач ПараметрыВМ, ЭлементыXML, Зависимости, Разделитель = " ")
	
	Если ТипЗнч(ПараметрыВМ) = Тип("Строка") Тогда
		ПроцессорXML = Новый СериализацияДанныхXML();
		ПараметрыВМ = ПроцессорXML.ПрочитатьИзФайла(ПараметрыВМ)["Параметры"];
	КонецЕсли;
	
	СтрокаКоманда = "";
	Для каждого Параметр Из ПараметрыВМ Цикл
		// Исключаем пустые
		Если Не ЗначениеЗаполнено(Параметр.Значение) Тогда
			Продолжить;
		КонецЕсли;
		
		// Исключаем зависимости
		Если Зависимости[Параметр.Ключ] <> Неопределено Тогда
			
			Пропустить = ЗначениеЗаполнено(ПараметрыВМ[Параметр.Ключ])
				И Не Параметр.Значение = "Ложь"
				И ЗначениеЗаполнено(ПараметрыВМ[Зависимости[Параметр.Ключ]])
				И Не ПараметрыВМ[Зависимости[Параметр.Ключ]] = "Ложь";
			
			Если Пропустить Тогда
				Продолжить;
			КонецЕсли;
		КонецЕсли;
		
		Атрибуты = ЭлементыXML[Параметр.Ключ]["_Атрибуты"];
		
		Если Атрибуты["type"] = Неопределено Тогда
			// Перебор заголовков
			Если ТипЗнч(Параметр.Значение) = Тип("Соответствие") Тогда
				ДопПараметры = ПараметрыИзФайлаВКоманду(Параметр.Значение,
						ЭлементыXML[Параметр.Ключ]["_Элементы"],
						Зависимости, ",");
				СтрокаКоманда = СтрокаКоманда + Разделитель + Атрибуты["yc"] + Разделитель + ДопПараметры;
			КонецЕсли;
		Иначе
			// Перебор параметров заголовков
			Если Атрибуты["type"] = "Число" Тогда
				Попытка
					ЗначениеЧисло = Число(Параметр.Значение);
				Исключение
					Лог.Ошибка("Не верный тип параметра: " + Параметр.Ключ);
					ВызватьИсключение("Не верный тип параметра: " + Параметр.Ключ);
				КонецПопытки;
			КонецЕсли;
			
			Если Атрибуты["type"] = "Булево" Тогда
				Если Параметр.Значение = "Истина" Тогда
					СтрокаКоманда = СтрокаКоманда + Разделитель + Атрибуты["yc"];
				Иначе
					Продолжить;
				КонецЕсли;
			Иначе
				СтрокаКоманда = ?(ЗначениеЗаполнено(СтрокаКоманда),
						СтрокаКоманда + Разделитель + Атрибуты["yc"],
						СтрокаКоманда + Атрибуты["yc"]);
				СтрокаКоманда = ?(СтрНайти(Атрибуты["yc"], "--"),
						СтрокаКоманда + " " + Параметр.Значение,
						СтрокаКоманда + Параметр.Значение);
			КонецЕсли;
		КонецЕсли;
	КонецЦикла;
	
	Возврат СтрокаКоманда;
КонецФункции

Лог = Логирование.ПолучитьЛог("oscript.lib.vporter");