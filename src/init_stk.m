% Start new instance
app = actxserver('STK11.application');
% get running server:
% app = actxGetRunningServer('STK11.application');
%STKXApplication = actxserver('STKX11.application');

% app.NoGraphics = 1;
% STKXApplication.NoGraphics = 1;

%app.Visible
%root = actxserver('AgStkObjects11.AgStkObjectRoot');
root = app.Personality2;

format long
scenario = root.Children.New('eScenario','walker_contact_plan');
%scenario = root.LoadScenario('C:\Users\Usuario\Desktop\STK Files\Anything\Anything.sc');
% scenario = root.CurrentScenario;
root.UnitPreferences.Item('DateFormat').SetCurrentUnit('UTCG');
scenario.SetTimePeriod('1 Jan 2025 16:00:00.000','2 Jan 2025 16:00:00.000');
root.UnitPreferences.Item('DateFormat').SetCurrentUnit('EpSec');
root.Rewind;