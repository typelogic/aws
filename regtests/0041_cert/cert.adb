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

--  This must be the exact same test than tgetparam. The only difference is
--  that it uses HTTPS protocol. We test that output is the same as the non
--  secure version.

with Ada.Text_IO;
with Ada.Exceptions;

with AWS.Server;
with AWS.Client;
with AWS.Config.Set;
with AWS.Status;
with AWS.MIME;
with AWS.Response;
with AWS.Parameters;
with AWS.Messages;
with AWS.Net.SSL.Certificate;
with AWS.URL;

procedure Cert is

   use Ada;
   use Ada.Text_IO;
   use AWS;

   function CB (Request : Status.Data) return Response.Data;

   procedure Display_Certificate (Socket : Net.SSL.Socket_Type);

   procedure Display_Certificate (Cert : Net.SSL.Certificate.Object);

   task Server is
      entry Started;
      entry Stopped;
   end Server;

   HTTP : AWS.Server.HTTP;

   --------
   -- CB --
   --------

   function CB (Request : Status.Data) return Response.Data is
      URI  : constant String                := Status.URI (Request);
      Sock : constant Net.Socket_Type'Class := Status.Socket (Request);
   begin
      if URI = "/simple" then

         New_Line;
         Put_Line ("Client certificate as received by the server:");
         Display_Certificate (Net.SSL.Socket_Type (Sock));

         return Response.Build (MIME.Text_HTML, "simple ok");
      else
         Put_Line ("Unknown URI " & URI);
         return Response.Build
           (MIME.Text_HTML, URI & " not found", Messages.S404);
      end if;
   end CB;

   -------------------------
   -- Display_Certificate --
   -------------------------

   procedure Display_Certificate (Cert : Net.SSL.Certificate.Object) is
      use type Net.SSL.Certificate.Object;
   begin
      if Cert = Net.SSL.Certificate.Undefined then
         Put_Line ("No certificate.");
      else
         Put_Line ("Subject : " & Net.SSL.Certificate.Subject (Cert));
         Put_Line ("Issuer  : " & Net.SSL.Certificate.Issuer (Cert));
      end if;
   end Display_Certificate;

   procedure Display_Certificate (Socket : Net.SSL.Socket_Type) is
      Cert : constant Net.SSL.Certificate.Object
        := Net.SSL.Certificate.Get (Socket);
   begin
      Display_Certificate (Cert);
   end Display_Certificate;

   ------------
   -- Server --
   ------------

   task body Server is
      Conf : Config.Object;
   begin
      Config.Set.Server_Port (Conf, 7429);
      Config.Set.Max_Connection (Conf, 5);
      Config.Set.Security (Conf, True);
      Config.Set.Exchange_Certificate (Conf, True);

      AWS.Server.Start (HTTP, CB'Unrestricted_Access, Conf);

      Put_Line ("Server started");
      New_Line;

      accept Started;

      select
         accept Stopped;
      or
         delay 5.0;
         Put_Line ("Too much time to do the job !");
      end select;

      AWS.Server.Shutdown (HTTP);
   exception
      when E : others =>
         Put_Line ("Server Error " & Exceptions.Exception_Information (E));
   end Server;

   -------------
   -- Request --
   -------------

   procedure Request (URL : String) is
      O_URL : constant AWS.URL.Object := AWS.URL.Parse (URL);
      R     : Response.Data;
      C     : Client.HTTP_Connection;
      Cert  : Net.SSL.Certificate.Object;
   begin
      Client.Create (C, URL, Certificate => "client.pem");

      Cert := Client.Get_Certificate (C);

      New_Line;
      Put_Line ("Server certificate as received by the client:");
      Display_Certificate (Cert);

      Client.Get (C, R, AWS.URL.Abs_Path (O_URL));

      Put_Line ("=> " & Response.Message_Body (R));
      New_Line;

      Client.Close (C);
   end Request;

begin
   Put_Line ("Start main, wait for server to start...");

   Server.Started;

   Request ("https://localhost:7429/simple");

   Server.Stopped;

exception
   when E : others =>
      Put_Line ("Main Error " & Exceptions.Exception_Information (E));
end Cert;
