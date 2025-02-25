{******************************************************************************}
{                                                                              }
{  Neon: Serialization Library for Delphi                                      }
{  Copyright (c) 2018-2019 Paolo Rossi                                         }
{  https://github.com/paolo-rossi/neon-library                                 }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit Neon.Core.Persistence.JSON;

interface

{$I Neon.inc}

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs,
  System.TypInfo, System.Generics.Collections, System.JSON, Data.DB,

  Neon.Core.Types,
  Neon.Core.Attributes,
  Neon.Core.Persistence,
  Neon.Core.DynamicTypes,
  Neon.Core.Utils;

type
  /// <summary>
  ///   JSON Serializer class
  /// </summary>
  TNeonSerializerJSON = class(TNeonBase, ISerializerContext)
  private
    /// <summary>
    ///   Writer for members of objects and records
    /// </summary>
    procedure WriteMembers(AType: TRttiType; AInstance: Pointer; AResult: TJSONValue);
  private
    /// <summary>
    ///   Writer for string types
    /// </summary>
    function WriteString(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for Char types
    /// </summary>
    function WriteChar(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for Boolean types
    /// </summary>
    function WriteBoolean(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for enums types <br />
    /// </summary>
    function WriteEnum(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for Integer types <br />
    /// </summary>
    function WriteInteger(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for float types
    /// </summary>
    function WriteFloat(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for TDate* types
    /// </summary>
    function WriteDate(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for Variant types
    /// </summary>
    /// <remarks>
    ///   The variant will be written as string
    /// </remarks>
    function WriteVariant(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for static and dynamic arrays
    /// </summary>
    function WriteArray(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for the set type
    /// </summary>
    /// <remarks>
    ///   The output is a string with the values comma separated and enclosed by square brackets
    /// </remarks>
    /// <returns>[First,Second,Third]</returns>
    function WriteSet(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for a record type
    /// </summary>
    /// <remarks>
    ///   For records the engine serialize the fields by default
    /// </remarks>
    function WriteRecord(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for a standard TObject (descendants)  type (no list, stream or streamable)
    /// </summary>
    function WriteObject(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for an Interface type
    /// </summary>
    /// <remarks>
    ///   The object that implements the interface is serialized
    /// </remarks>
    function WriteInterface(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for TStream (descendants) objects
    /// </summary>
    function WriteStream(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for TDataSet (descendants) objects
    /// </summary>
    function WriteDataSet(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;

    /// <summary>
    ///   Writer for "Enumerable" objects (Lists, Generic Lists, TStrings, etc...)
    /// </summary>
    /// <remarks>
    ///   Objects must have GetEnumerator, Clear, Add methods
    /// </remarks>
    function WriteEnumerable(const AValue: TValue; ANeonObject: TNeonRttiObject; AList: IDynamicList): TJSONValue;
    function IsEnumerable(const AValue: TValue; out AList: IDynamicList): Boolean;

    /// <summary>
    ///   Writer for "Dictionary" objects (TDictionary, TObjectDictionary)
    /// </summary>
    /// <remarks>
    ///   Objects must have Keys, Values, GetEnumerator, Clear, Add methods
    /// </remarks>
    function WriteEnumerableMap(const AValue: TValue; ANeonObject: TNeonRttiObject; AMap: IDynamicMap): TJSONValue;
    function IsEnumerableMap(const AValue: TValue; out AMap: IDynamicMap): Boolean;

    /// <summary>
    ///   Writer for "Streamable" objects
    /// </summary>
    /// <remarks>
    ///   Objects must have LoadFromStream and SaveToStream methods
    /// </remarks>
    function WriteStreamable(const AValue: TValue; ANeonObject: TNeonRttiObject; AStream: IDynamicStream): TJSONValue;
    function IsStreamable(const AValue: TValue; out AStream: IDynamicStream): Boolean;

    /// <summary>
    ///   Writer for "Nullable" records
    /// </summary>
    /// <remarks>
    ///   Record must have HasValue and GetValue methods
    /// </remarks>
    function WriteNullable(const AValue: TValue; ANeonObject: TNeonRttiObject; ANullable: IDynamicNullable): TJSONValue;
    function IsNullable(const AValue: TValue; out ANullable: IDynamicNullable): Boolean;
  protected
    /// <summary>
    ///   Function to be called by a custom serializer method (ISerializeContext)
    /// </summary>
    function WriteDataMember(const AValue: TValue): TJSONValue; overload;

    /// <summary>
    ///   This method chooses the right Writer based on the Kind of the AValue parameter
    /// </summary>
    function WriteDataMember(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue; overload;
  public
    constructor Create(const AConfig: INeonConfiguration);

    /// <summary>
    ///   Serialize any Delphi type into a JSONValue, the Delphi type must be passed as a TValue
    /// </summary>
    function ValueToJSON(const AValue: TValue): TJSONValue;

    /// <summary>
    ///   Serialize any Delphi objects into a JSONValue
    /// </summary>
    function ObjectToJSON(AObject: TObject): TJSONValue;
  end;

  TNeonDeserializerParam = record
    JSONValue: TJSONValue;
    RttiType: TRttiType;
    NeonObject: TNeonRttiObject;
    procedure Default;
  end;

  /// <summary>
  ///   JSON Deserializer class
  /// </summary>
  TNeonDeserializerJSON = class(TNeonBase, IDeserializerContext)
  private
    procedure ReadMembers(AType: TRttiType; AInstance: Pointer; AJSONObject: TJSONObject);
  private
    function ReadString(const AParam: TNeonDeserializerParam): TValue;
    function ReadChar(const AParam: TNeonDeserializerParam): TValue;
    function ReadEnum(const AParam: TNeonDeserializerParam): TValue;
    function ReadInteger(const AParam: TNeonDeserializerParam): TValue;
    function ReadInt64(const AParam: TNeonDeserializerParam): TValue;
    function ReadFloat(const AParam: TNeonDeserializerParam): TValue;
    function ReadSet(const AParam: TNeonDeserializerParam): TValue;
    function ReadVariant(const AParam: TNeonDeserializerParam): TValue;
  private
    function ReadArray(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
    function ReadDynArray(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
    function ReadObject(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
    function ReadInterface(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
    function ReadRecord(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
    function ReadDataSet(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
    function ReadStream(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;

	// Dynamic types
    function ReadStreamable(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
    function ReadEnumerable(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
    function ReadEnumerableMap(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
    function ReadNullable(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
  private
    function ReadDataMember(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue; overload;
    function ReadDataMember(const AParam: TNeonDeserializerParam; const AData: TValue): TValue; overload;
  public
    constructor Create(const AConfig: INeonConfiguration);

    procedure JSONToObject(AObject: TObject; AJSON: TJSONValue);
    procedure JSONToDataSet(AJSON: TJSONValue; ADataSet: TDataSet);
    function JSONToTValue(AJSON: TJSONValue; AType: TRttiType): TValue; overload;
    function JSONToTValue(AJSON: TJSONValue; AType: TRttiType; const AData: TValue): TValue; overload;
    function JSONToArray(AJSON: TJSONValue; AType: TRttiType): TValue;
  end;

  /// <summary>
  ///   Static utility class for serializing and deserializing Delphi types
  /// </summary>
  TNeon = class
  private
    /// <summary>
    ///   Prints a TJSONValue in a single line or formatted (PrettyPrinting)
    /// </summary>
    class procedure PrintToWriter(AJSONValue: TJSONValue; AWriter: TTextWriter; APretty: Boolean); static;

  public
    /// <summary>
    ///   Prints a TJSONValue in a single line or formatted (PrettyPrinting)
    /// </summary>
    class function Print(AJSONValue: TJSONValue; APretty: Boolean): string; static;

    /// <summary>
    ///   Prints a TJSONValue in a single line or formatted (PrettyPrinting)
    /// </summary>
    class procedure PrintToStream(AJSONValue: TJSONValue; AStream: TStream; APretty: Boolean); static;
  public
    /// <summary>
    ///   Serializes a value based type (record, string, integer, etc...) to a TJSONValue
    /// </summary>
    /// <remarks>
    ///   A default configuration object will be provided
    /// </remarks>
    class function ValueToJSON(const AValue: TValue): TJSONValue; overload;

    /// <summary>
    ///   Serializes a value based type (record, string, integer, etc...) to a TJSONValue
    ///   with a given configuration
    /// </summary>
    class function ValueToJSON(const AValue: TValue; AConfig: INeonConfiguration): TJSONValue; overload;

    /// <summary>
    ///   Serializes an object based type to a TJSONValue with a default configuration
    /// </summary>
    class function ObjectToJSON(AObject: TObject): TJSONValue; overload;

    /// <summary>
    ///   Serializes an object based type to a TJSONValue with a given configuration <br />
    /// </summary>
    class function ObjectToJSON(AObject: TObject; AConfig: INeonConfiguration): TJSONValue; overload;

    /// <summary>
    ///   Serializes an object based type to a string with a default configuration <br />
    /// </summary>
    class function ObjectToJSONString(AObject: TObject): string; overload;

    /// <summary>
    ///   Serializes an object based type to a string with a given configuration <br />
    /// </summary>
    class function ObjectToJSONString(AObject: TObject; AConfig: INeonConfiguration): string; overload;
  public
    /// <summary>
    ///   Deserializes a TJSONValue into a TObject with a given configuration
    /// </summary>
    class procedure JSONToObject(AObject: TObject; AJSON: TJSONValue; AConfig: INeonConfiguration); overload;
    /// <summary>
    ///   Deserializes a string into a TObject with a given configuration
    /// </summary>
    class procedure JSONToObject(AObject: TObject; const AJSON: string; AConfig: INeonConfiguration); overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a TRttiType with a default configuration
    /// </summary>
    class function JSONToObject(AType: TRttiType; AJSON: TJSONValue): TObject; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a TRttiType with a given configuration
    /// </summary>
    class function JSONToObject(AType: TRttiType; AJSON: TJSONValue; AConfig: INeonConfiguration): TObject; overload;

    /// <summary>
    ///   Deserializes a string into a TRttiType with a default configuration
    /// </summary>
    class function JSONToObject(AType: TRttiType; const AJSON: string): TObject; overload;

    /// <summary>
    ///   Deserializes a string into a TRttiType with a given configuration
    /// </summary>
    class function JSONToObject(AType: TRttiType; const AJSON: string; AConfig: INeonConfiguration): TObject; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a generic type &lt;T&gt; with a default
    ///   configuration
    /// </summary>
    class function JSONToObject<T: class, constructor>(AJSON: TJSONValue): T; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a generic type &lt;T&gt; with a given
    ///   configuration <br />
    /// </summary>
    class function JSONToObject<T: class, constructor>(AJSON: TJSONValue; AConfig: INeonConfiguration): T; overload;

    /// <summary>
    ///   Deserializes a string into a generic type &lt;T&gt; with a default
    ///   configuration <br />
    /// </summary>
    class function JSONToObject<T: class, constructor>(const AJSON: string): T; overload;

    /// <summary>
    ///   Deserializes a string into a generic type &lt;T&gt; with a given configuration <br />
    /// </summary>
    class function JSONToObject<T: class, constructor>(const AJSON: string; AConfig: INeonConfiguration): T; overload;
  public
    /// <summary>
    ///   Deserializes a TJSONValue into a TRttiType value based with a default
    ///   configuration <br />
    /// </summary>
    class function JSONToValue(ARttiType: TRttiType; AJSON: TJSONValue): TValue; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a TRttiType value based with a given
    ///   configuration
    /// </summary>
    class function JSONToValue(ARttiType: TRttiType; AJSON: TJSONValue; AConfig: INeonConfiguration): TValue; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a generic type &lt;T&gt; (value based) with a
    ///   default configuration
    /// </summary>
    class function JSONToValue<T>(AJSON: TJSONValue): T; overload;

    /// <summary>
    ///   Deserializes a TJSONValue into a generic type &lt;T&gt; (value based) with a
    ///   given configuration <br />
    /// </summary>
    class function JSONToValue<T>(AJSON: TJSONValue; AConfig: INeonConfiguration): T; overload;
  end;

implementation

uses
  System.Variants;

{ TNeonSerializerJSON }

constructor TNeonSerializerJSON.Create(const AConfig: INeonConfiguration);
begin
  inherited Create(AConfig);
  FOperation := TNeonOperation.Serialize;
end;

function TNeonSerializerJSON.IsEnumerable(const AValue: TValue; out AList: IDynamicList): Boolean;
begin
  AList := TDynamicList.GuessType(AValue.AsObject);
  Result := Assigned(AList);
end;

function TNeonSerializerJSON.IsEnumerableMap(const AValue: TValue; out AMap: IDynamicMap): Boolean;
begin
  AMap := TDynamicMap.GuessType(AValue.AsObject);
  Result := Assigned(AMap);
end;

function TNeonSerializerJSON.IsNullable(const AValue: TValue; out ANullable: IDynamicNullable): Boolean;
begin
  ANullable := TDynamicNullable.GuessType(AValue);
  Result := Assigned(ANullable);
end;

function TNeonSerializerJSON.IsStreamable(const AValue: TValue; out AStream: IDynamicStream): Boolean;
begin
  AStream := TDynamicStream.GuessType(AValue.AsObject);
  Result := Assigned(AStream);
end;

function TNeonSerializerJSON.ObjectToJSON(AObject: TObject): TJSONValue;
begin
  FOriginalInstance := AObject;
  if not Assigned(AObject) then
    Exit(TJSONObject.Create);

  Result := WriteDataMember(AObject);
end;

function TNeonSerializerJSON.ValueToJSON(const AValue: TValue): TJSONValue;
begin
  FOriginalInstance := AValue;

  Result := WriteDataMember(AValue);
end;

function TNeonSerializerJSON.WriteArray(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LIndex, LCount: Integer;
  LArray: TJSONArray;
begin
  LCount := AValue.GetArrayLength;
  if ANeonObject.NeonInclude.Value = IncludeIf.NotEmpty then
    if LCount = 0 then
      Exit(nil);

  LArray := TJSONArray.Create;
  for LIndex := 0 to LCount - 1 do
    LArray.AddElement(WriteDataMember(AValue.GetArrayElement(LIndex)));

  Result := LArray;
end;

function TNeonSerializerJSON.WriteBoolean(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  Result := TJSONBool.Create(AValue.AsBoolean);
end;

function TNeonSerializerJSON.WriteChar(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LStr: string;
begin
  LStr := AValue.AsString;
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotEmpty, IncludeIf.NotDefault:
    begin
      if (LStr = #0) or LStr.IsEmpty then
        Exit(nil);
    end;
  end;

  if (LStr = #0) or LStr.IsEmpty then
    Result := TJSONString.Create('')
  else
    Result := TJSONString.Create(AValue.AsString);
end;

function TNeonSerializerJSON.WriteDataMember(const AValue: TValue): TJSONValue;
var
  LNeonObject: TNeonRttiObject;
  LRttiType: TRttiType;
begin
  LRttiType := TRttiUtils.Context.GetType(AValue.TypeInfo);

  LNeonObject := TNeonRttiObject.Create(LRttiType, FOperation);
  LNeonObject.ParseAttributes;
  try
    Result := WriteDataMember(AValue, LNeonObject);
  finally
    LNeonObject.Free;
  end;
end;

function TNeonSerializerJSON.WriteDataMember(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LCustomSer: TCustomSerializer;
  LDynamicType: IDynamicType;


  LDynamicMap: IDynamicMap absolute LDynamicType;
  LDynamicList: IDynamicList absolute LDynamicType;
  LDynamicStream: IDynamicStream absolute LDynamicType;
  LDynamicNullable: IDynamicNullable absolute LDynamicType;
begin
  Result := nil;

  LCustomSer := FConfig.Serializers.GetSerializer(AValue.TypeInfo);
  if Assigned(LCustomSer) then
  begin
    Result := LCustomSer.Serialize(AValue, Self);
    Exit(Result);
  end;

  case AValue.Kind of
    tkChar,
    tkWChar:
    begin
      Result := WriteChar(AValue, ANeonObject);
    end;

    tkString,
    tkLString,
    tkWString,
    tkUString:
    begin
      Result := WriteString(AValue, ANeonObject);
    end;

    tkEnumeration:
    begin
      if AValue.TypeInfo = System.TypeInfo(Boolean) then
        Result := WriteBoolean(AValue, ANeonObject)
      else
        Result := WriteEnum(AValue, ANeonObject);
    end;

    tkInteger,
    tkInt64:
    begin
      Result := WriteInteger(AValue, ANeonObject);
    end;

    tkFloat:
    begin
      if (AValue.TypeInfo = System.TypeInfo(TDateTime)) or
         (AValue.TypeInfo = System.TypeInfo(TDate)) or
         (AValue.TypeInfo = System.TypeInfo(TTime)) then
        Result := WriteDate(AValue, ANeonObject)
      else
        Result := WriteFloat(AValue, ANeonObject);
    end;

    tkClass:
    begin
      if AValue.AsObject = nil then
      begin
        case ANeonObject.NeonInclude.Value of
          IncludeIf.NotNull, IncludeIf.NotEmpty, IncludeIf.NotDefault:
          Exit(nil);
        else
          Exit(TJSONNull.Create);
        end;
      end
      else if AValue.AsObject is TDataSet then
        Result := WriteDataSet(AValue, ANeonObject)
      else if AValue.AsObject is TStream then
        Result := WriteStream(AValue, ANeonObject)
      else if IsEnumerableMap(AValue, LDynamicMap) then
        Result := WriteEnumerableMap(AValue, ANeonObject, LDynamicMap)
      else if IsEnumerable(AValue, LDynamicList) then
        Result := WriteEnumerable(AValue, ANeonObject, LDynamicList)
      else if IsStreamable(AValue, LDynamicStream) then
        Result := WriteStreamable(AValue, ANeonObject, LDynamicStream)
      else
        Result := WriteObject(AValue, ANeonObject);
    end;

    tkArray:
    begin
      Result := WriteArray(AValue, ANeonObject);
    end;

    tkDynArray:
    begin
      Result := WriteArray(AValue, ANeonObject);
    end;

    tkSet:
    begin
      Result := WriteSet(AValue, ANeonObject);
    end;

    tkRecord:
    begin
      if IsNullable(AValue, LDynamicNullable) then
        Result := WriteNullable(AValue, ANeonObject, LDynamicNullable)
      else
        Result := WriteRecord(AValue, ANeonObject);
    end;

    tkInterface:
    begin
      Result := WriteInterface(AValue, ANeonObject);
    end;

    tkVariant:
    begin
      Result := WriteVariant(AValue, ANeonObject);
    end;
    {
    tkUnknown,
    tkMethod,
    tkPointer,
    tkProcedure,
    tkClassRef:
    }
  end;
end;

function TNeonSerializerJSON.WriteDataSet(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LDataSet: TDataSet;
begin
  LDataSet := AValue.AsObject as TDataSet;

  if ANeonObject.NeonInclude.Value = IncludeIf.NotEmpty then
    if LDataSet.IsEmpty then
      Exit(nil);

  Result := TDataSetUtils.DataSetToJSONArray(LDataSet, FConfig);
end;

function TNeonSerializerJSON.WriteDate(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotEmpty, IncludeIf.NotDefault:
    begin
      if AValue.AsExtended = 0 then
        Exit(nil);
    end;
  end;
  Result := TJSONString.Create(TJSONUtils.DateToJSON(AValue.AsType<TDateTime>, FConfig.UseUTCDate))
end;

function TNeonSerializerJSON.WriteEnum(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LName: string;
begin
  LName := GetEnumName(AValue.TypeInfo, AValue.AsOrdinal);

  if Length(ANeonObject.NeonEnumNames) > 0 then
  begin
    if (AValue.AsOrdinal >= Low(ANeonObject.NeonEnumNames)) and
       (AValue.AsOrdinal <= High(ANeonObject.NeonEnumNames)) then
      LName := ANeonObject.NeonEnumNames[AValue.AsOrdinal]
  end;

  Result := TJSONString.Create(LName);
end;

function TNeonSerializerJSON.WriteFloat(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotEmpty, IncludeIf.NotDefault:
    begin
      if AValue.AsExtended = 0 then
        Exit(nil);
    end;
  end;

  Result := TJSONNumber.Create(AValue.AsExtended);
end;

function TNeonSerializerJSON.WriteInteger(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotDefault:
    begin
      if AValue.AsInt64 = 0 then
        Exit(nil);
    end;
  end;

  Result := TJSONNumber.Create(AValue.AsInt64);
end;

function TNeonSerializerJSON.WriteInterface(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LInterface: IInterface;
  LObject: TObject;
begin
  LInterface := AValue.AsInterface;
  LObject := LInterface as TObject;
  Result := WriteObject(LObject, ANeonObject);
end;

procedure TNeonSerializerJSON.WriteMembers(AType: TRttiType; AInstance: Pointer; AResult: TJSONValue);
var
  LJSONValue: TJSONValue;
  LMembers: TNeonRttiMembers;
  LNeonMember: TNeonRttiMember;
begin
  LMembers := GetNeonMembers(AInstance, AType);
  LMembers.FilterSerialize;
  try
    for LNeonMember in LMembers do
    begin
      if LNeonMember.Serializable then
      begin
        try
          LJSONValue := WriteDataMember(LNeonMember.GetValue, LNeonMember);
          if Assigned(LJSONValue) then
            (AResult as TJSONObject).AddPair(GetNameFromMember(LNeonMember), LJSONValue);
        except
          on E: Exception do
          begin
            LogError(Format('Error converting member [%s] of type [%s]: %s',
              [LNeonMember.Name, AType.Name, E.Message]));
          end;
        end;
      end;
    end;
  finally
    LMembers.Free;
  end;
end;

function TNeonSerializerJSON.WriteNullable(const AValue: TValue; ANeonObject: TNeonRttiObject; ANullable: IDynamicNullable): TJSONValue;
begin
  Result := nil;

  if Assigned(ANullable) and ANullable.HasValue then
    Result := WriteDataMember(ANullable.GetValue);
end;

function TNeonSerializerJSON.WriteObject(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LObject: TObject;
  LType: TRttiType;
begin
  LObject := AValue.AsObject;
  LType := TRttiUtils.Context.GetType(LObject.ClassType);

  Result := TJSONObject.Create;
  try
    WriteMembers(LType, LObject, Result);
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotEmpty, IncludeIf.NotDefault:
      begin
        if (Result as TJSONObject).Count = 0 then
          FreeAndNil(Result);
      end;
    end;
  except
    FreeAndNil(Result);
  end;
end;

function TNeonSerializerJSON.WriteEnumerable(const AValue: TValue; ANeonObject: TNeonRttiObject; AList: IDynamicList): TJSONValue;
var
  LJSONValue: TJSONValue;
begin
  // Is not an Enumerable compatible object
  if not Assigned(AList) then
    Exit(nil);
  if ANeonObject.NeonInclude.Value = IncludeIf.NotEmpty then
    if AList.Count = 0 then
      Exit(nil);

  Result := TJSONArray.Create;
  while AList.MoveNext do
  begin
    LJSONValue := WriteDataMember(AList.Current);
    (Result as TJSONArray).AddElement(LJSONValue);
  end;
end;

function TNeonSerializerJSON.WriteEnumerableMap(const AValue: TValue; ANeonObject: TNeonRttiObject; AMap: IDynamicMap): TJSONValue;
var
  LName: string;
  LJSONName: TJSONValue;
  LJSONValue: TJSONValue;
  LKeyValue, LValValue: TValue;
begin
  // Is not an EnumerableMap-compatible object
  if not Assigned(AMap) then
    Exit(nil);

  case ANeonObject.NeonInclude.Value of
    IncludeIf.Always:
    begin
      if not Assigned(AMap) then
        Exit(TJSONNull.Create);
    end;
    IncludeIf.NotNull:
    begin
      if not Assigned(AMap) then
        Exit(nil);
    end;
    IncludeIf.NotEmpty:
    begin
      if AMap.Count = 0 then
        Exit(nil);
    end;
    IncludeIf.NotDefault: ;
  end;

  Result := TJSONObject.Create;
  try
    while AMap.MoveNext do
    begin
      LKeyValue := AMap.CurrentKey;
      LValValue := AMap.CurrentValue;

      LJSONName := WriteDataMember(LKeyValue);
      try
        LJSONValue := WriteDataMember(LValValue);

        if LJSONName is TJSONString then
          LName := (LJSONName as TJSONString).Value
        else if AMap.KeyIsString then
          LName := AMap.KeyToString(LKeyValue);

        (Result as TJSONObject).AddPair(LName, LJSONValue);

        if LName.IsEmpty then
          raise Exception.Create('Dictionary [Key]: type not supported');
      finally
        LJSONName.Free;
      end;
    end;
  except
    on E: Exception do
    begin
      FErrors.Add(E.Message);
      FreeAndNil(Result);
    end;
  end;
end;

function TNeonSerializerJSON.WriteRecord(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LType: TRttiType;
begin
  Result := TJSONObject.Create;
  LType := TRttiUtils.Context.GetType(AValue.TypeInfo);
  try
    WriteMembers(LType, AValue.GetReferenceToRawData, Result);
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotEmpty, IncludeIf.NotDefault:
      begin
        if ANeonObject.NeonInclude.Value = IncludeIf.NotEmpty then
          if (Result as TJSONObject).Count = 0 then
            FreeAndNil(Result);
      end;
    end;
  except
    FreeAndNil(Result);
  end;
end;

function TNeonSerializerJSON.WriteSet(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LRes: string;
begin
  LRes := SetToString(AValue.TypeInfo, Integer(AValue.GetReferenceToRawData^), True);

  if ANeonObject.NeonInclude.Value = IncludeIf.NotEmpty then
    if LRes = '[]' then
      Exit(nil);

  Result := TJSONString.Create(LRes);
end;

function TNeonSerializerJSON.WriteStream(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
var
  LStream: TStream;
  LBase64: string;
begin
  LStream := AValue.AsObject as TStream;

  if LStream.Size = 0 then
  begin
    case ANeonObject.NeonInclude.Value of
      IncludeIf.NotEmpty, IncludeIf.NotDefault: Exit(nil);
    else
      Exit(TJSONString.Create(''));
    end;
  end;

  LStream.Position := soFromBeginning;
  LBase64 := TBase64.Encode(LStream);
  Result := TJSONString.Create(LBase64);
end;

function TNeonSerializerJSON.WriteStreamable(const AValue: TValue; ANeonObject: TNeonRttiObject; AStream: IDynamicStream): TJSONValue;
var
  LBinaryStream: TMemoryStream;
  LBase64: string;
begin
  Result := nil;

  if Assigned(AStream) then
  begin
    LBinaryStream := TMemoryStream.Create;
    try
      AStream.SaveToStream(LBinaryStream);
      LBinaryStream.Position := soFromBeginning;
      LBase64 := TBase64.Encode(LBinaryStream);
      if IsOriginalInstance(AValue) then
        Result := TJSONObject.Create.AddPair('$value', LBase64)
      else
        Result := TJSONString.Create(LBase64);
    finally
      LBinaryStream.Free;
    end;
  end;
end;

function TNeonSerializerJSON.WriteString(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotEmpty, IncludeIf.NotDefault:
    begin
      if AValue.AsString.IsEmpty then
        Exit(nil);
    end;
  end;

  Result := TJSONString.Create(AValue.AsString);
end;

function TNeonSerializerJSON.WriteVariant(const AValue: TValue; ANeonObject: TNeonRttiObject): TJSONValue;
begin
  case ANeonObject.NeonInclude.Value of
    IncludeIf.NotNull:
    begin
      if VarIsNull(AValue.AsVariant) then
        Exit(nil);
    end;
    IncludeIf.NotEmpty:
    begin
      if VarIsEmpty(AValue.AsVariant) then
        Exit(nil);
    end;
  end;

  Result := TJSONString.Create(AValue.AsVariant);
end;

{ TNeonDeserializerJSON }

constructor TNeonDeserializerJSON.Create(const AConfig: INeonConfiguration);
begin
  inherited Create(AConfig);
  FOperation := TNeonOperation.Deserialize;
end;

function TNeonDeserializerJSON.ReadArray(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LIndex: NativeInt;
  LItemValue: TValue;
  LJSONArray: TJSONArray;
  LParam: TNeonDeserializerParam;
begin
  // TValue record copy (but the TValue only copy the reference to Data)
  Result := AData;
  LParam.NeonObject := AParam.NeonObject;

  // Clear (and Free) previous elements?
  LJSONArray := AParam.JSONValue as TJSONArray;
  LParam.RttiType := (AParam.RttiType as TRttiArrayType).ElementType;

  // Check static array bounds
  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LParam.JSONValue := LJSONArray.Items[LIndex];
    LItemValue := TRttiUtils.CreateNewValue(LParam.RttiType);
    LItemValue := ReadDataMember(LParam, Result);
    Result.SetArrayElement(LIndex, LItemValue);
  end;
end;

function TNeonDeserializerJSON.ReadDynArray(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LIndex: NativeInt;
  LItemValue: TValue;
  LArrayLength: NativeInt;
  LJSONArray: TJSONArray;
  LParam: TNeonDeserializerParam;
begin
  Result := AData;

  LParam.NeonObject := AParam.NeonObject;
  // Clear (and Free) previous elements?
  LJSONArray := AParam.JSONValue as TJSONArray;
  LParam.RttiType := (AParam.RttiType as TRttiDynamicArrayType).ElementType;
  LArrayLength := LJSONArray.Count;
  DynArraySetLength(PPointer(Result.GetReferenceToRawData)^, Result.TypeInfo, 1, @LArrayLength);

  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LParam.JSONValue := LJSONArray.Items[LIndex];

    LItemValue := TRttiUtils.CreateNewValue(LParam.RttiType);
    LItemValue := ReadDataMember(LParam, LItemValue);

    Result.SetArrayElement(LIndex, LItemValue);
  end;
end;

function TNeonDeserializerJSON.ReadChar(const AParam: TNeonDeserializerParam):
    TValue;
begin
  if (AParam.JSONValue is TJSONNull) or AParam.JSONValue.Value.IsEmpty then
    Exit(#0);

  case AParam.RttiType.TypeKind of
    // AnsiChar
    tkChar:  Result := TValue.From<UTF8Char>(UTF8Char(AParam.JSONValue.Value.Chars[0]));

    // WideChar
    tkWChar: Result := TValue.From<Char>(AParam.JSONValue.Value.Chars[0]);
  end;
end;

function TNeonDeserializerJSON.ReadDataMember(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
var
  LParam: TNeonDeserializerParam;
begin
  LParam.JSONValue := AJSONValue;
  LParam.RttiType := AType;
  LParam.NeonObject := TNeonRttiObject.Create(AType, FOperation);
  LParam.NeonObject.ParseAttributes;
  try
    Result := ReadDataMember(LParam, AData);
  finally
    LParam.NeonObject.Free;
  end;
end;

function TNeonDeserializerJSON.ReadDataMember(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LCustom: TCustomSerializer;
begin
  if AParam.JSONValue is TJSONNull then
    Exit(TValue.Empty);

  // if there is a custom serializer
  LCustom := FConfig.Serializers.GetSerializer(AParam.RttiType.Handle);

  if Assigned(LCustom) then
  begin
    Result := LCustom.Deserialize(AParam.JSONValue, AData, Self);
    Exit(Result);
  end;

  case AParam.RttiType.TypeKind of
    // Simple types
    tkInt64:       Result := ReadInt64(AParam);
    tkInteger:     Result := ReadInteger(AParam);
    tkChar:        Result := ReadChar(AParam);
    tkWChar:       Result := ReadChar(AParam);
    tkEnumeration: Result := ReadEnum(AParam);
    tkFloat:       Result := ReadFloat(AParam);
    tkLString:     Result := ReadString(AParam);
    tkWString:     Result := ReadString(AParam);
    tkUString:     Result := ReadString(AParam);
    tkString:      Result := ReadString(AParam);
    tkSet:         Result := ReadSet(AParam);
    tkVariant:     Result := ReadVariant(AParam);
    tkArray:       Result := ReadArray(AParam, AData);
    tkDynArray:    Result := ReadDynArray(AParam, AData);

    // Complex types
    tkClass:
    begin
      { TODO -opaolo -c : Refactor Read*Object function (boolean result) 20/05/2017 12:25:19 }
      if AData.AsObject is TDataSet then
        Result := ReadDataSet(AParam, AData)
      else if AData.AsObject is TStream then
        Result := ReadStream(AParam, AData)
      else
      begin
        if ReadEnumerableMap(AParam, AData) then
          Result := AData
        else if ReadEnumerable(AParam, AData) then
          Result := AData
        else if ReadStreamable(AParam, AData) then
          Result := AData
        else
          Result := ReadObject(AParam, AData);
      end;
    end;
    tkInterface:   Result := ReadInterface(AParam, AData);
    tkRecord:
    begin
      if ReadNullable(AParam, AData) then
        Result := AData
      else
       Result := ReadRecord(AParam, AData);
    end;

    // Not supported (yet)
    {
    tkUnknown: ;
    tkClassRef: ;
    tkPointer: ;
    tkMethod: ;
    tkProcedure: ;
    }
    else Result := TValue.Empty;
  end;
end;

function TNeonDeserializerJSON.ReadDataSet(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LJSONArray: TJSONArray;
  LJSONItem: TJSONObject;
  LJSONField: TJSONValue;
  LDataSet: TDataSet;
  LIndex: Integer;
  LItemIntex: Integer;
  LName: string;
begin
  Result := AData;
  LDataSet := AData.AsObject as TDataSet;
  LJSONArray := AParam.JSONValue as TJSONArray;

  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LJSONItem := LJSONArray.Items[LIndex] as TJSONObject;

    LDataSet.Append;
    for LItemIntex := 0 to LDataSet.Fields.Count - 1 do
    begin
      LName := LDataSet.Fields[LItemIntex].FieldName;

      LJSONField := LJSONItem.GetValue(LName);
      if Assigned(LJSONField) then
      begin
        case LDataSet.Fields[LItemIntex].DataType of
          ftDataSet: JSONToDataSet(LJSONField, (LDataSet.Fields[LItemIntex] as TDataSetField).NestedDataSet);
          ftBlob: TDataSetUtils.Base64ToBlobField(LJSONField.Value, LDataSet.Fields[LItemIntex] as TBlobField);       
        else
          begin
            { TODO -opaolo -c : Be more specific (field and json type) 27/04/2017 17:16:09 }
            LDataSet.FieldByName(LName).AsString := LJSONField.Value;
          end;
        end;
      end;
    end;
    LDataSet.Post;
  end;
end;

function TNeonDeserializerJSON.ReadEnum(const AParam: TNeonDeserializerParam): TValue;
var
  LIndex, LOrdinal: Integer;
begin
  if AParam.RttiType.Handle = System.TypeInfo(Boolean) then
  begin
    if AParam.JSONValue is TJSONTrue then
      Result := True
    else if AParam.JSONValue is TJSONFalse then
      Result := False
    else
      raise ENeonException.Create('Invalid JSON value. Boolean expected');
  end
  else
  begin
    LOrdinal := -1;
    if Length(AParam.NeonObject.NeonEnumNames) > 0 then
    begin
      for LIndex := Low(AParam.NeonObject.NeonEnumNames) to High(AParam.NeonObject.NeonEnumNames) do
        if AParam.JSONValue.Value = AParam.NeonObject.NeonEnumNames[LIndex] then
          LOrdinal := LIndex;
    end;
    if LOrdinal = -1 then
      LOrdinal := GetEnumValue(AParam.RttiType.Handle, AParam.JSONValue.Value);
    TValue.Make(LOrdinal, AParam.RttiType.Handle, Result);
  end;
end;

function TNeonDeserializerJSON.ReadEnumerable(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
var
  LItemValue: TValue;
  LList: IDynamicList;
  LJSONArray: TJSONArray;
  LIndex: Integer;
  LParam: TNeonDeserializerParam;
begin
  Result := False;
  LParam.NeonObject := AParam.NeonObject;
  LList := TDynamicList.GuessType(AData.AsObject);
  if Assigned(LList) then
  begin
    Result := True;
    LParam.RttiType := LList.GetItemType;
    LList.Clear;

    LJSONArray := AParam.JSONValue as TJSONArray;

    for LIndex := 0 to LJSONArray.Count - 1 do
    begin
      LParam.JSONValue := LJSONArray.Items[LIndex];

      LItemValue := LList.NewItem;
      LItemValue := ReadDataMember(LParam, LItemValue);

      LList.Add(LItemValue);
    end;
  end;
end;

function TNeonDeserializerJSON.ReadEnumerableMap(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
var
  LMap: IDynamicMap;
{$IFDEF HAS_NEW_JSON}
  LEnum: TJSONObject.TEnumerator;
{$ELSE}
  LEnum: TJSONPairEnumerator;
{$ENDIF}
  LKey, LValue: TValue;
  LParamKey, LParamValue: TNeonDeserializerParam;
begin
  Result := False;
  LParamKey.NeonObject := AParam.NeonObject;
  LParamValue.NeonObject := AParam.NeonObject;

  LMap := TDynamicMap.GuessType(AData.AsObject);
  if Assigned(LMap) then
  begin
    Result := True;
    LParamKey.RttiType := LMap.GetKeyType;
    LParamValue.RttiType := LMap.GetValueType;
    LMap.Clear;

    LEnum := (AParam.JSONValue as TJSONObject).GetEnumerator;
    try
      while LEnum.MoveNext do
      begin
        LKey := LMap.NewKey;
        LParamKey.JSONValue := LEnum.Current.JsonString;
        if LParamKey.RttiType.TypeKind = tkClass then
          LMap.KeyFromString(LKey, LEnum.Current.JsonString.Value)
        else
          LKey := ReadDataMember(LParamKey, LKey);

        LValue := LMap.NewValue;
        LParamValue.JSONValue := LEnum.Current.JsonValue;
        LValue := ReadDataMember(LParamValue, LValue);

        LMap.Add(LKey, LValue);
      end;
    finally
      LEnum.Free;
    end;
  end;
end;

function TNeonDeserializerJSON.ReadFloat(const AParam: TNeonDeserializerParam): TValue;
begin
  if AParam.JSONValue is TJSONNull then
    Exit(0);

  if AParam.RttiType.Handle = System.TypeInfo(TDate) then
    Result := TValue.From<TDate>(TJSONUtils.JSONToDate(AParam.JSONValue.Value, True))
  else if AParam.RttiType.Handle = System.TypeInfo(TTime) then
    Result := TValue.From<TTime>(TJSONUtils.JSONToDate(AParam.JSONValue.Value, True))
  else if AParam.RttiType.Handle = System.TypeInfo(TDateTime) then
    Result := TValue.From<TDateTime>(TJSONUtils.JSONToDate(AParam.JSONValue.Value, FConfig.UseUTCDate))
  else
  begin
    if AParam.JSONValue is TJSONNumber then
      Result := (AParam.JSONValue as TJSONNumber).AsDouble
    else
      raise ENeonException.Create('Invalid JSON value. Float expected');
  end;
end;

function TNeonDeserializerJSON.ReadInt64(const AParam: TNeonDeserializerParam): TValue;
var
  LNumber: TJSONNumber;
begin
  if AParam.JSONValue is TJSONNull then
    Exit(0);

  LNumber := AParam.JSONValue as TJSONNumber;
  Result := LNumber.AsInt64
end;

function TNeonDeserializerJSON.ReadInteger(const AParam: TNeonDeserializerParam): TValue;
var
  LNumber: TJSONNumber;
begin
  if AParam.JSONValue is TJSONNull then
    Exit(0);

  LNumber := AParam.JSONValue as TJSONNumber;
  Result := LNumber.AsInt;
end;

function TNeonDeserializerJSON.ReadInterface(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
begin
  Result := AData;
end;

procedure TNeonDeserializerJSON.ReadMembers(AType: TRttiType; AInstance: Pointer; AJSONObject: TJSONObject);
var
  LMembers: TNeonRttiMembers;
  LNeonMember: TNeonRttiMember;
  LMemberValue: TValue;
  LParam: TNeonDeserializerParam;
begin
  LMembers := GetNeonMembers(AInstance, AType);
  LMembers.FilterDeserialize;
  try
    for LNeonMember in LMembers do
    begin
      if LNeonMember.Serializable then
      begin
        LParam.NeonObject := LNeonMember;
        LParam.RttiType := LNeonMember.RttiType;

        //Look for a JSON with the calculated Member Name
        LParam.JSONValue := AJSONObject.GetValue(GetNameFromMember(LNeonMember));

        // Property not found in JSON, continue to the next one
        if not Assigned(LParam.JSONValue) then
          Continue;

        LMemberValue := ReadDataMember(LParam, LNeonMember.GetValue);
        LNeonMember.SetValue(LMemberValue);
      end;
    end;
  finally
    LMembers.Free;
  end;
end;

function TNeonDeserializerJSON.ReadNullable(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
var
  LNullable: IDynamicNullable;
  LValue: TValue;
  LValueType: TRttiType;
begin
  Result := False;
  LNullable := TDynamicNullable.GuessType(AData);
  if Assigned(LNullable) then
  begin
    Result := True;
    LValueType := TRttiUtils.Context.GetType(LNullable.GetValueType);
    LValue := JSONToTValue(AParam.JSONValue, LValueType);
    LNullable.SetValue(LValue);
  end;
end;

function TNeonDeserializerJSON.ReadObject(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LJSONObject: TJSONObject;
  LPData: Pointer;
begin
  Result := AData;

  LPData := AData.AsObject;
  if not Assigned(LPData) then
    Exit;

  LJSONObject := AParam.JSONValue as TJSONObject;

  if (AParam.RttiType.TypeKind = tkClass) or (AParam.RttiType.TypeKind = tkInterface) then
    ReadMembers(AParam.RttiType, LPData, LJSONObject);
end;

function TNeonDeserializerJSON.ReadRecord(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LJSONObject: TJSONObject;
  LPData: Pointer;
begin
  Result := AData;
  LPData := AData.GetReferenceToRawData;

  if not Assigned(LPData) then
    Exit;

  // Objects, Records, Interfaces are all represented by JSON objects
  LJSONObject := AParam.JSONValue as TJSONObject;

  ReadMembers(AParam.RttiType, LPData, LJSONObject);
end;

function TNeonDeserializerJSON.ReadSet(const AParam: TNeonDeserializerParam): TValue;
var
  LSetStr: string;
begin
  LSetStr := AParam.JSONValue.Value;
  LSetStr := LSetStr.Replace(sLineBreak, '', [rfReplaceAll]);
  LSetStr := LSetStr.Replace(' ', '', [rfReplaceAll]);
  TValue.Make(StringToSet(AParam.RttiType.Handle, LSetStr), AParam.RttiType.Handle, Result);
end;

function TNeonDeserializerJSON.ReadStream(const AParam: TNeonDeserializerParam; const AData: TValue): TValue;
var
  LStream: TStream;
begin
  Result := AData;
  LStream := AData.AsObject as TStream;
  LStream.Position := soFromBeginning;

  TBase64.Decode(AParam.JSONValue.Value, LStream);
end;

function TNeonDeserializerJSON.ReadStreamable(const AParam: TNeonDeserializerParam; const AData: TValue): Boolean;
var
  LStream: TMemoryStream;
  LStreamable: IDynamicStream;
  LJSONValue: TJSONValue;
begin
  Result := False;
  LStreamable := TDynamicStream.GuessType(AData.AsObject);
  if Assigned(LStreamable) then
  begin
    Result := True;
    LStream := TMemoryStream.Create;
    try
      if IsOriginalInstance(AData) then
        LJSONValue := (AParam.JSONValue as TJSONObject).GetValue('$value')
      else
        LJSONValue := AParam.JSONValue;

      TBase64.Decode(LJSONValue.Value, LStream);
      LStream.Position := soFromBeginning;
      LStreamable.LoadFromStream(LStream);
    finally
      LStream.Free;
    end;
  end;
end;

function TNeonDeserializerJSON.ReadString(const AParam: TNeonDeserializerParam): TValue;
begin
  case AParam.RttiType.TypeKind of
    // AnsiString
    tkLString: Result := TValue.From<UTF8String>(UTF8String(AParam.JSONValue.Value));

    //WideString
    tkWString: Result := TValue.From<string>(AParam.JSONValue.Value);

    //UnicodeString
    tkUString: Result := TValue.From<string>(AParam.JSONValue.Value);

    //ShortString
    tkString:  Result := TValue.From<UTF8String>(UTF8String(AParam.JSONValue.Value));

  // Future string types treated as unicode strings
  else
    Result := AParam.JSONValue.Value;
  end;
end;

function TNeonDeserializerJSON.ReadVariant(const AParam: TNeonDeserializerParam): TValue;
begin

end;

function TNeonDeserializerJSON.JSONToArray(AJSON: TJSONValue; AType: TRttiType): TValue;
begin
  Result := ReadDataMember(AJSON, AType, TValue.Empty);
end;

procedure TNeonDeserializerJSON.JSONToDataSet(AJSON: TJSONValue; ADataSet: TDataSet);
begin
  ReadDataMember(AJSON, TRttiUtils.Context.GetType(ADataSet.ClassType), ADataSet);
end;

procedure TNeonDeserializerJSON.JSONToObject(AObject: TObject; AJSON: TJSONValue);
var
  LType: TRttiType;
  LValue: TValue;
begin
  FOriginalInstance := AObject;
  LType := TRttiUtils.Context.GetType(AObject.ClassType);
  LValue := AObject;
  ReadDataMember(AJSON, LType, AObject);
end;

function TNeonDeserializerJSON.JSONToTValue(AJSON: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
begin
  FOriginalInstance := AData;
  Result := ReadDataMember(AJSON, AType, AData);
end;

function TNeonDeserializerJSON.JSONToTValue(AJSON: TJSONValue; AType: TRttiType): TValue;
begin
  //FOriginalInstance := TValue.Empty;
  Result := ReadDataMember(AJSON, AType, TValue.Empty);
end;

{ TNeon }

class function TNeon.JSONToObject(AType: TRttiType; AJSON: TJSONValue): TObject;
begin
  Result := JSONToObject(AType, AJSON, TNeonConfiguration.Default);
end;

class function TNeon.JSONToObject(AType: TRttiType; const AJSON: string): TObject;
begin
  Result := JSONToObject(AType, AJSON, TNeonConfiguration.Default);
end;

class function TNeon.JSONToObject(AType: TRttiType; AJSON: TJSONValue; AConfig: INeonConfiguration): TObject;
begin
  Result := TRttiUtils.CreateInstance(AType);
  JSONToObject(Result, AJSON, AConfig);
end;

class function TNeon.JSONToObject<T>(AJSON: TJSONValue): T;
begin
  Result := JSONToObject(TRttiUtils.Context.GetType(TClass(T)), AJSON) as T;
end;

class procedure TNeon.JSONToObject(AObject: TObject; const AJSON: string; AConfig: INeonConfiguration);
var
  LJSON: TJSONValue;
begin
  LJSON := TJSONObject.ParseJSONValue(AJSON);
  try
    JSONToObject(AObject, LJSON, AConfig);
  finally
    LJSON.Free;
  end;
end;

class function TNeon.JSONToObject<T>(const AJSON: string): T;
begin
  Result := JSONToObject(TRttiUtils.Context.GetType(TClass(T)), AJSON) as T;
end;

class function TNeon.ObjectToJSON(AObject: TObject; AConfig: INeonConfiguration): TJSONValue;
var
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    Result := LWriter.ObjectToJSON(AObject);
  finally
    LWriter.Free;
  end;
end;

class function TNeon.ObjectToJSONString(AObject: TObject): string;
begin
  Result := TNeon.ObjectToJSONString(AObject, TNeonConfiguration.Default);
end;

class function TNeon.ObjectToJSON(AObject: TObject): TJSONValue;
begin
  Result := TNeon.ObjectToJSON(AObject, TNeonConfiguration.Default);
end;

class function TNeon.ObjectToJSONString(AObject: TObject; AConfig: INeonConfiguration): string;
var
  LJSON: TJSONValue;
begin
  LJSON := ObjectToJSON(AObject, AConfig);
  try
    Result := Print(LJSON, AConfig.GetPrettyPrint);
  finally
    LJSON.Free;
  end;
end;

class function TNeon.Print(AJSONValue: TJSONValue; APretty: Boolean): string;
var
  LWriter: TStringWriter;
begin
  LWriter := TStringWriter.Create;
  try
    TNeon.PrintToWriter(AJSONValue, LWriter, APretty);
    Result := LWriter.ToString;
  finally
    LWriter.Free;
  end;
end;

class procedure TNeon.PrintToStream(AJSONValue: TJSONValue; AStream: TStream; APretty: Boolean);
var
  LWriter: TStreamWriter;
begin
  LWriter := TStreamWriter.Create(AStream);
  try
    TNeon.PrintToWriter(AJSONValue, LWriter, APretty);
  finally
    LWriter.Free;
  end;
end;

class procedure TNeon.PrintToWriter(AJSONValue: TJSONValue; AWriter: TTextWriter; APretty: Boolean);
var
  LJSONString: string;
  LChar: Char;
  LOffset: Integer;
  LIndex: Integer;
  LOutsideString: Boolean;

  function Spaces(AOffset: Integer): string;
  begin
    Result := StringOfChar(#32, AOffset * 2);
  end;

begin
  if not APretty then
  begin
    AWriter.Write(AJSONValue.ToJSON);
    exit;
  end;

  LOffset := 0;
  LOutsideString := True;
  LJSONString := AJSONValue.ToJSON;

  for LIndex := 0 to Length(LJSONString) - 1 do
  begin
    LChar := LJSONString.Chars[LIndex];

    if LChar = '"' then
      LOutsideString := not LOutsideString;

    if LOutsideString and (LChar = '{') then
    begin
      Inc(LOffset);
      AWriter.Write(LChar);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
    end
    else if LOutsideString and (LChar = '}') then
    begin
      Dec(LOffset);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
      AWriter.Write(LChar);
    end
    else if LOutsideString and (LChar = ',') then
    begin
      AWriter.Write(LChar);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
    end
    else if LOutsideString and (LChar = '[') then
    begin
      Inc(LOffset);
      AWriter.Write(LChar);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
    end
    else if LOutsideString and (LChar = ']') then
    begin
      Dec(LOffset);
      AWriter.Write(sLineBreak);
      AWriter.Write(Spaces(LOffset));
      AWriter.Write(LChar);
    end
    else if LOutsideString and (LChar = ':') then
    begin
      AWriter.Write(LChar);
      AWriter.Write(' ');
    end
    else
      AWriter.Write(LChar);
  end;
end;

class function TNeon.ValueToJSON(const AValue: TValue): TJSONValue;
begin
  Result := TNeon.ValueToJSON(AValue, TNeonConfiguration.Default);
end;

class function TNeon.ValueToJSON(const AValue: TValue; AConfig: INeonConfiguration): TJSONValue;
var
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    Result := LWriter.ValueToJSON(AValue);
  finally
    LWriter.Free;
  end;
end;

class procedure TNeon.JSONToObject(AObject: TObject; AJSON: TJSONValue; AConfig: INeonConfiguration);
var
  LReader: TNeonDeserializerJSON;
begin
  LReader := TNeonDeserializerJSON.Create(AConfig);
  try
    LReader.JSONToObject(AObject, AJSON);
  finally
    LReader.Free;
  end;
end;

class function TNeon.JSONToObject(AType: TRttiType; const AJSON: string; AConfig: INeonConfiguration): TObject;
var
  LJSON: TJSONValue;
begin
  LJSON := TJSONObject.ParseJSONValue(AJSON);
  try
    Result := TRttiUtils.CreateInstance(AType);
    JSONToObject(Result, LJSON, AConfig);
  finally
    LJSON.Free;
  end;
end;

class function TNeon.JSONToObject<T>(AJSON: TJSONValue; AConfig: INeonConfiguration): T;
begin
  Result := JSONToObject(TRttiUtils.Context.GetType(TClass(T)), AJSON, AConfig) as T;
end;

class function TNeon.JSONToObject<T>(const AJSON: string; AConfig: INeonConfiguration): T;
begin
  Result := JSONToObject(TRttiUtils.Context.GetType(TClass(T)), AJSON, AConfig) as T;
end;

class function TNeon.JSONToValue(ARttiType: TRttiType; AJSON: TJSONValue;
  AConfig: INeonConfiguration): TValue;
var
  LDes: TNeonDeserializerJSON;
begin
  LDes := TNeonDeserializerJSON.Create(AConfig);
  try
    Result := LDes.JSONToTValue(AJSON, ARttiType);
  finally
    LDes.Free;
  end;
end;

class function TNeon.JSONToValue(ARttiType: TRttiType; AJSON: TJSONValue): TValue;
begin
  Result := JSONToValue(ARttiType, AJSON, TNeonConfiguration.Default);
end;

class function TNeon.JSONToValue<T>(AJSON: TJSONValue; AConfig: INeonConfiguration): T;
var
  LDes: TNeonDeserializerJSON;
  LValue: TValue;
begin
  LDes := TNeonDeserializerJSON.Create(AConfig);
  try
    LValue := LDes.JSONToTValue(AJSON, TRttiUtils.Context.GetType(TypeInfo(T)));
    Result := LValue.AsType<T>;
  finally
    LDes.Free;
  end;
end;

class function TNeon.JSONToValue<T>(AJSON: TJSONValue): T;
begin
  Result := JSONToValue<T>(AJSON, TNeonConfiguration.Default);
end;

{ TNeonDeserializerParam }

procedure TNeonDeserializerParam.Default;
begin
  JSONValue := nil;
  RttiType := nil;
  NeonObject := nil;
end;

end.
