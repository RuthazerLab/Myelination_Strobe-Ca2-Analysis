function timestamp_string = timestamp(getc,format,overnight)
%{
Convert passed clock variable to timestamp string
getc: clock variable
format: format of output date string
overnight: (default 1) if =1, 0h-4h will be marked as 24h-28h of previous day
*If you are doing experiment on last day of month, tough luck it's not handled so just don't go overnight :)

Available formats: (using 2018 Jan 1 as example)
ymdt - 20180101_12.12 (default)
time - 12.12
date - 20180101

to do: add "overnight"
%}


if ~exist('format','var') || isempty(format)
    format = 'ymdt';
end

if ~exist('overnight','var') || isempty(overnight)
    overnight = 1;
end

%overnight = 1;

t_hour=num2str(getc(4));
t_day=num2str(getc(3));
if overnight
    if(getc(4)<4)
    t_hour=str2double(t_hour)+24;
    t_hour=num2str(t_hour);
    t_day=str2double(t_day)-1;
    t_day=num2str(t_day);
    end
end


t_year=num2str(getc(1));
if(str2double(t_year)<10)
    t_year=['0' t_year];
end;
t_month=num2str(getc(2));
if(str2double(t_month)<10)
    t_month=['0' t_month];
end;
if(str2double(t_day)<10)
    t_day=['0' t_day];
end;
if(str2double(t_hour)<10)
    t_hour=['0' t_hour];
end;
t_min=num2str(getc(5));
if(str2double(t_min)<10)
    t_min=['0' t_min];
end;

if strcmp(format,'time')
    timestamp_string = [t_hour '.' t_min];
elseif strcmp(format,'date')
    timestamp_string = [t_year t_month t_day];
else
    timestamp_string = [t_year t_month t_day '_' t_hour '.' t_min];
end
end
