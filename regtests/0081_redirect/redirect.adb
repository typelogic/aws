------------------------------------------------------------------------------
--                              Ada Web Server                              --
--                                                                          --
--                     Copyright (C) 2003-2012, AdaCore                     --
--                                                                          --
--  This is free software;  you can redistribute it  and/or modify it       --
--  under terms of the  GNU General Public License as published  by the     --
--  Free Software  Foundation;  either version 3,  or (at your option) any  --
--  later version.  This software is distributed in the hope  that it will  --
--  be useful, but WITHOUT ANY WARRANTY;  without even the implied warranty --
--  of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU     --
--  General Public License for  more details.                               --
--                                                                          --
--  You should have  received  a copy of the GNU General  Public  License   --
--  distributed  with  this  software;   see  file COPYING3.  If not, go    --
--  to http://www.gnu.org/licenses for a complete copy of the license.      --
------------------------------------------------------------------------------

with Ada.Text_IO;

with AWS.Client;
with AWS.Messages;
with AWS.MIME;
with AWS.Response;
with AWS.Server;
with AWS.Status;
with AWS.Utils;

with Get_Free_Port;

procedure Redirect is

   use Ada;
   use AWS;
   use type AWS.Messages.Status_Code;

   WS   : Server.HTTP;
   Port : Natural := 1239;

   --------
   -- CB --
   --------

   function CB (Request : Status.Data) return Response.Data is
      URI : constant String := Status.URI (Request);
   begin
      if URI = "/first" then
         return Response.URL ("/second");

      elsif URI = "/second" then
         return Response.Build (MIME.Text_HTML, "That's good!");

      else
         return Response.Build (MIME.Text_HTML, "URI not supported");
      end if;
   end CB;

   -------------
   -- Call_It --
   -------------

   procedure Call_It is
      R : Response.Data;
   begin
      R := Client.Get ("http://localhost:" & Utils.Image (Port) & "/first");

      if Response.Status_Code (R) = Messages.S302 then
         Text_IO.Put_Line ("OK, status is good");

      else
         Text_IO.Put_Line
           ("NOK, wrong status "
            & Messages.Image (Response.Status_Code (R)));
      end if;

      Text_IO.Put_Line (Response.Location (R));
   end Call_It;

begin
   Get_Free_Port (Port);

   Server.Start
     (WS, "file", CB'Unrestricted_Access, Port => Port, Max_Connection => 5);
   Text_IO.Put_Line ("started"); Ada.Text_IO.Flush;

   Call_It;

   Server.Shutdown (WS);
   Text_IO.Put_Line ("shutdown");
end Redirect;
