--
-- PostgreSQL database dump
--

-- Dumped from database version 10.3
-- Dumped by pg_dump version 11.2

-- Started on 2019-04-08 03:54:16

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE ntet;
--
-- TOC entry 3035 (class 1262 OID 57344)
-- Name: ntet; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE ntet WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Spanish_Colombia.1252' LC_CTYPE = 'Spanish_Colombia.1252';


ALTER DATABASE ntet OWNER TO postgres;

\connect ntet

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 3 (class 3079 OID 123085)
-- Name: cube; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS cube WITH SCHEMA public;


--
-- TOC entry 3036 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION cube; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION cube IS 'data type for multidimensional cubes';


--
-- TOC entry 2 (class 3079 OID 123172)
-- Name: earthdistance; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS earthdistance WITH SCHEMA public;


--
-- TOC entry 3037 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION earthdistance; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION earthdistance IS 'calculate great-circle distances on the surface of the Earth';


--
-- TOC entry 271 (class 1255 OID 123239)
-- Name: abonar_carrera(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.abonar_carrera() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
begin 
    UPDATE taxista SET saldo = 
    (saldo + (1.609344 * 0.6 * (select costo from tarifa where tarifa.id_tarifa = new.id_tarifa) * (new.coords_inicial <@> new.coords_final))) 
    where taxista.id_taxista = new.id_taxista;                                                              
    
    RETURN NEW;
end;
$$;


ALTER FUNCTION public.abonar_carrera() OWNER TO postgres;

--
-- TOC entry 274 (class 1255 OID 148003)
-- Name: borrar_usuario(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.borrar_usuario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        begin
            update carrera set num_cel_u = 'Deleted User' where carrera.num_cel_u = old.num_cel_u;
            return old;
        end;
    $$;


ALTER FUNCTION public.borrar_usuario() OWNER TO postgres;

--
-- TOC entry 264 (class 1255 OID 147969)
-- Name: closest(point, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.closest(lugar_recogida point, numero_de_celular character varying, rango double precision) 
RETURNS TABLE(placa character varying, id_taxista character varying, distancia double precision)
    LANGUAGE plpgsql
    AS $$ 
		BEGIN
			if (not exists (select * from carreras_en_curso where numero_de_celular = num_cel_u)) then
				return query
				select taxistas_en_servicio.placa, taxistas_en_servicio.id_taxista, (lugar_recogida <@> coordenadas) as distancia
				from taxistas_en_servicio
				where (((1.609344 * (lugar_recogida <@> coordenadas)) <= rango) and estado = true);
			else
				return query select 'error'::character varying as placa, 'error'::character varying as id_taxista, 0::double precision as distancia;
			end if;
		END;
	$$;


ALTER FUNCTION public.closest(lugar_recogida point, numero_de_celular character varying) OWNER TO postgres;

--
-- TOC entry 254 (class 1255 OID 123210)
-- Name: cobrar_carrera(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cobrar_carrera() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
begin 
UPDATE usuario SET deuda = (deuda + (1.609344 * (select costo from tarifa where tarifa.id_tarifa = new.id_tarifa) * (new.coords_inicial <@> new.coords_final))) where usuario.num_cel_u = new.num_cel_u;                                                              
    RETURN NEW;
end;
$$;


ALTER FUNCTION public.cobrar_carrera() OWNER TO postgres;

--
-- TOC entry 224 (class 1255 OID 147964)
-- Name: comenzar_carrera(character varying, character varying, character varying, point, point); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.comenzar_carrera(numero_cel character varying, identificacion character varying, placa_c character varying, coord_i point, coord_f point) 
RETURNS TABLE(logrado boolean)
    LANGUAGE plpgsql
    AS $$
        begin
                if (exists (select * from usuario where num_cel_u = numero_cel) and
                    exists (select * from taxistas_en_servicio where placa = placa_c and estado = true) and
				   not exists (select * from carreras_en_curso carreraa where id_taxista = identificacion or numero_cel = num_cel_u or placa = placa_c))
                    then            
                        insert into carreras_en_curso values (numero_cel, 1, placa_c, identificacion, current_timestamp(0), coord_i, coord_f);
                        update taxistas_en_servicio set estado = false  where id_taxista = identificacion;
						return query select true as estado;
					else
						return query select false as estado;
                    end if;
        end
    $$;


ALTER FUNCTION public.comenzar_carrera(numero_cel character varying, identificacion character varying, placa_c character varying, coord_i point, coord_f point) OWNER TO postgres;

--
-- TOC entry 273 (class 1255 OID 148022)
-- Name: esta_en_carrera(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.esta_en_carrera(numerocel character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
		BEGIN
			IF (exists(select * from carreras_en_curso where num_cel_u = numeroCel)) then
				return true;
			else
				return false;
			end if;
		END;
	$$;


ALTER FUNCTION public.esta_en_carrera(numerocel character varying) OWNER TO postgres;

--
-- TOC entry 285 (class 1255 OID 148023)
-- Name: existe_usuario(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.existe_usuario(numerocel character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
		BEGIN
			IF (exists(select * from usuario where num_cel_u = numeroCel)) then
				return true;
			else
				return false;
			end if;
		END;
	$$;


ALTER FUNCTION public.existe_usuario(numerocel character varying) OWNER TO postgres;

--
-- TOC entry 283 (class 1255 OID 123313)
-- Name: ingresar_puntaje(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.ingresar_puntaje(puntaje_otorgado integer, identificacion character varying, numero_cel character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
	begin 
    	if (exists (select * from puntaje_log where id_taxista = identificacion)) 
		then
		update carrera SET califico = true where (carrera.califico = false 
							and id_taxista = identificacion
							and numero_cel = (select num_cel_u from carrera where califico = false and id_taxista = identificacion and num_cel_u = numero_cel limit 1)
							and fecha_carrera = (select fecha_carrera from carrera where califico = false and id_taxista = identificacion and num_cel_u = numero_cel limit 1));
		update puntaje_log set acomulado = acomulado + puntaje_otorgado where id_taxista = identificacion;										 
												 
		UPDATE taxista SET puntaje =  cast((select acomulado from puntaje_log where puntaje_log.id_taxista = identificacion) as decimal) /
									  (select count(*) from (select * from carrera where id_taxista = identificacion and califico = true)q1) 		 
					   where id_taxista = identificacion;	
    	else
		UPDATE taxista SET puntaje = puntaje_otorgado where id_taxista = identificacion;
		insert into puntaje_log values (identificacion, puntaje_otorgado); 
		update carrera SET califico = true where (carrera.califico = false 
							and id_taxista = identificacion
							and numero_cel = (select num_cel_u from carrera where califico = false and id_taxista = identificacion and num_cel_u = numero_cel limit 1)
							and fecha_carrera = (select fecha_carrera from carrera where califico = false and id_taxista = identificacion and num_cel_u = numero_cel limit 1));												 
		END IF;
		
	end
$$;


ALTER FUNCTION public.ingresar_puntaje(puntaje_otorgado integer, identificacion character varying, numero_cel character varying) OWNER TO postgres;

--
-- TOC entry 216 (class 1255 OID 147976)
-- Name: loggear_taxista(character varying, point, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.loggear_taxista(identificacion character varying, ubicacion point, placa_s character varying) 
RETURNS TABLE(placa character varying, id_taxista character varying, nombre text)
    LANGUAGE plpgsql
    AS $$ 										 
		begin
																																	 
		if (exists (select * from taxista where taxista.id_taxista = identificacion) and exists(select * from taxi where placa_s = taxi.placa)
		   and not exists (select * from taxistas_en_servicio where taxistas_en_servicio.id_taxista = identificacion or taxistas_en_servicio.placa = placa_s))
		then			
			insert into registro values(placa_s, identificacion, current_timestamp(0));
			insert into taxistas_en_servicio values(identificacion, placa_s, ubicacion, true);																												  
			return query select taxi.placa, taxista.id_taxista, (nombre_t || ' ' || apellido_t) as nombre from taxi,taxista 
				where taxi.placa = placa_s and taxista.id_taxista = identificacion;	
			
		end if;																				
		end;		
	$$;


ALTER FUNCTION public.loggear_taxista(identificacion character varying, ubicacion point, placa_s character varying) OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 148028)
-- Name: logout_taxista(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.logout_taxista(identificacion character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
		begin
			if( exists(select * from taxistas_en_servicio where  taxistas_en_servicio.id_taxista = identificacion) and 
			    not exists(select * from carreras_en_curso where id_taxista = identificacion)) then
				delete from taxistas_en_servicio where taxistas_en_servicio.id_taxista = identificacion;
				update registro set salida_turno = current_timestamp(0) where id_taxista = identificacion and salida_turno is null;
				return true;
			else
				return false;	
			end if;
		end;
		$$;


ALTER FUNCTION public.logout_taxista(identificacion character varying) OWNER TO postgres;

--
-- TOC entry 275 (class 1255 OID 131592)
-- Name: registrar_carrera(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.registrar_carrera() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
		begin
			insert into carrera values (old.num_cel_u, old.id_tarifa, old.placa, old.id_taxista, old.fecha_carrera, old.coords_inicial, old.coords_final, false, current_timestamp(0));
			return old;
		end;
	$$;


ALTER FUNCTION public.registrar_carrera() OWNER TO postgres;

--
-- TOC entry 291 (class 1255 OID 147994)
-- Name: registrar_fecha_dir_fav(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.registrar_fecha_dir_fav() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
begin 
	UPDATE dir_fav SET fecha_de_registro = CURRENT_TIMESTAMP(0) where dir_fav.id_dir_fav = new.id_dir_fav;                                                              
    RETURN NEW;
end;
$$;


ALTER FUNCTION public.registrar_fecha_dir_fav() OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 123251)
-- Name: registrar_fecha_taxi(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.registrar_fecha_taxi() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
begin 
	UPDATE taxi SET fecha_de_adquisicion = CURRENT_TIMESTAMP(0) where taxi.placa = new.placa;                                                              
    RETURN NEW;
end;
$$;


ALTER FUNCTION public.registrar_fecha_taxi() OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 147996)
-- Name: registrar_fecha_taxista(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.registrar_fecha_taxista() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
begin 
	UPDATE taxista SET fecha_de_ingreso = CURRENT_DATE where taxista.id_taxista = new.id_taxista;                                                              
    RETURN NEW;
end;
$$;


ALTER FUNCTION public.registrar_fecha_taxista() OWNER TO postgres;

--
-- TOC entry 287 (class 1255 OID 123247)
-- Name: registrar_fecha_usuario(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.registrar_fecha_usuario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
begin 
	UPDATE usuario SET fecha_de_registro = CURRENT_DATE where usuario.num_cel_u = new.num_cel_u;                                                              
    RETURN NEW;
end;
$$;


ALTER FUNCTION public.registrar_fecha_usuario() OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 123300)
-- Name: taxista_a_usuario(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.taxista_a_usuario(numero_de_celular character varying) RETURNS TABLE(nombre_completo text, numero_de_celular character varying, numero_de_viajes bigint)
    LANGUAGE sql
    AS $$
		select (nombre_u || ' ' || apellido_u) as nombre_completo, numero_de_celular,
			(select cuenta from (select num_cel_u, count(coords_inicial) as cuenta 
 				from (select usuario.num_cel_u, coords_inicial from carrera right join usuario on usuario.num_cel_u = carrera.num_cel_u) 
					q1 group by num_cel_u)q2 where num_cel_u = numero_de_celular) as numero_de_viajes
		from usuario
		where num_cel_u = numero_de_celular;															  
	   $$;


ALTER FUNCTION public.taxista_a_usuario(numero_de_celular character varying) OWNER TO postgres;

--
-- TOC entry 255 (class 1255 OID 147961)
-- Name: terminar_carrera(character varying, character varying, character varying, point); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.terminar_carrera(numero_cel character varying, identificacion character varying, placa_c character varying, coord_f point) RETURNS TABLE(costo double precision)
    LANGUAGE plpgsql
    AS $$
		begin
			if (exists (select * from carreras_en_curso where id_taxista = identificacion and numero_cel = num_cel_u and placa = placa_c)) then
				update carreras_en_curso set coords_final = coord_f;
				delete from carreras_en_curso where num_cel_u = numero_cel;		
				update taxistas_en_servicio set estado = true  where id_taxista = identificacion;
				return query select ((select tarifa.costo from tarifa where id_tarifa = 1) * 1.609344 * (coords_inicial <@> coord_f)) as costo 
									from carrera where num_cel_u = numero_cel order by fecha_fin_carrera DESC limit 1;
			end if;
		end;
	$$;


ALTER FUNCTION public.terminar_carrera(numero_cel character varying, identificacion character varying, placa_c character varying, coord_f point) OWNER TO postgres;

--
-- TOC entry 282 (class 1255 OID 123299)
-- Name: usuario_a_taxista(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.usuario_a_taxista(identificacion character varying, placa_taxi character varying) RETURNS 
TABLE(nombre_completo text, numero_de_celular character varying, placa character varying, marca_y_modelo text, numero_de_viajes bigint, puntaje double precision)
    LANGUAGE sql
    AS $$ 
        SELECT (nombre_t || ' ' || apellido_t) as nombre_completo, num_cel_t as numero_de_celular,            
        placa_taxi, (select (marca || ' ' || modelo) from taxi where placa = placa_taxi) as marca_y_modelo, 
	    (select cuenta from (select id_taxista, count(coords_inicial) as cuenta 
 			from (select taxista.id_taxista, coords_inicial from carrera right join taxista on taxista.id_taxista = carrera.id_taxista ) q1  
				 group by id_taxista) q2 where id_taxista = identificacion) as numero_de_viajes,
        puntaje 
        FROM taxista
        WHERE id_taxista = identificacion; 
    $$;


ALTER FUNCTION public.usuario_a_taxista(identificacion character varying, placa_taxi character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 205 (class 1259 OID 123213)
-- Name: carrera; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.carrera (
    num_cel_u character varying(20) NOT NULL,
    id_tarifa integer NOT NULL,
    placa character varying(20) NOT NULL,
    id_taxista character varying(50) NOT NULL,
    fecha_carrera timestamp(6) with time zone NOT NULL,
    coords_inicial point NOT NULL,
    coords_final point NOT NULL,
    califico boolean NOT NULL,
    fecha_fin_carrera timestamp with time zone NOT NULL
);


ALTER TABLE public.carrera OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 131559)
-- Name: carreras_en_curso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.carreras_en_curso (
    num_cel_u character varying(20) NOT NULL,
    id_tarifa integer NOT NULL,
    placa character varying(20) NOT NULL,
    id_taxista character varying(50) NOT NULL,
    fecha_carrera timestamp(6) with time zone NOT NULL,
    coords_inicial point NOT NULL,
    coords_final point NOT NULL
);


ALTER TABLE public.carreras_en_curso OWNER TO postgres;

--
-- TOC entry 201 (class 1259 OID 106620)
-- Name: dir_fav; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dir_fav (
    num_cel_u character varying(20) NOT NULL,
    nombre_dir text NOT NULL,
    coords_gps_u point NOT NULL,
    fecha_de_registro timestamp(0) with time zone,
    id_dir_fav bigint NOT NULL
);


ALTER TABLE public.dir_fav OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 147977)
-- Name: dir_fav_id_dir_fav_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dir_fav_id_dir_fav_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dir_fav_id_dir_fav_seq OWNER TO postgres;

--
-- TOC entry 3041 (class 0 OID 0)
-- Dependencies: 212
-- Name: dir_fav_id_dir_fav_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dir_fav_id_dir_fav_seq OWNED BY public.dir_fav.id_dir_fav;


--
-- TOC entry 200 (class 1259 OID 81925)
-- Name: taxista; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.taxista (
    id_taxista character varying(20) NOT NULL,
    nombre_t character varying(50) NOT NULL,
    apellido_t character varying(50) NOT NULL,
    puntaje double precision DEFAULT 0,
    num_cel_t character varying(13) NOT NULL,
    saldo double precision DEFAULT 0 NOT NULL,
    password_t text NOT NULL,
    num_cuenta text NOT NULL,
    fecha_de_ingreso date,
    CONSTRAINT puntaje_correcto CHECK (((puntaje >= (0.0)::double precision) AND (puntaje <= (5.0)::double precision)))
);


ALTER TABLE public.taxista OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 123328)
-- Name: perfiles_taxistas; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.perfiles_taxistas AS
 SELECT (((taxista.nombre_t)::text || ' '::text) || (taxista.apellido_t)::text) AS nombre_completo,
    taxista.num_cel_t AS numero_de_celular,
    taxista.id_taxista AS numero_de_identificacion,
    q3.distancia AS distancia_total_viajada,
    q2.cuenta AS numero_de_viajes,
    (CURRENT_DATE - taxista.fecha_de_ingreso) AS dias_desde_ingreso,
    taxista.saldo
   FROM ((public.taxista
     JOIN ( SELECT q1.id_taxista,
            count(q1.coords_inicial) AS cuenta
           FROM ( SELECT taxista_1.id_taxista,
                    carrera.coords_inicial
                   FROM (public.carrera
                     RIGHT JOIN public.taxista taxista_1 ON (((taxista_1.id_taxista)::text = (carrera.id_taxista)::text)))) q1
          GROUP BY q1.id_taxista) q2 USING (id_taxista))
     JOIN ( SELECT q1.id_taxista,
            COALESCE(sum(((1.609344)::double precision * (q1.coords_inicial OPERATOR(public.<@>) q1.coords_final))), (0)::double precision) AS distancia
           FROM ( SELECT taxista_1.id_taxista,
                    carrera.coords_inicial,
                    carrera.coords_final
                   FROM (public.carrera
                     RIGHT JOIN public.taxista taxista_1 ON (((taxista_1.id_taxista)::text = (carrera.id_taxista)::text)))) q1
          GROUP BY q1.id_taxista) q3 USING (id_taxista))
  WHERE ((taxista.id_taxista)::text = (taxista.id_taxista)::text)
  ORDER BY (((taxista.nombre_t)::text || ' '::text) || (taxista.apellido_t)::text);


ALTER TABLE public.perfiles_taxistas OWNER TO postgres;

--
-- TOC entry 198 (class 1259 OID 74041)
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario (
    num_cel_u character varying(13) NOT NULL,
    nombre_u character varying(50) NOT NULL,
    apellido_u character varying(50) NOT NULL,
    tarjeta_credito text NOT NULL,
    password text NOT NULL,
    deuda double precision DEFAULT 0 NOT NULL,
    fecha_de_registro date
);


ALTER TABLE public.usuario OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 123287)
-- Name: perfiles_usuarios; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.perfiles_usuarios AS
 SELECT (((usuario.nombre_u)::text || ' '::text) || (usuario.apellido_u)::text) AS nombre_completo,
    usuario.num_cel_u AS numero_de_celular,
    q3.distancia AS distancia_total_viajada,
    q2.cuenta AS numero_de_viajes,
    (CURRENT_DATE - usuario.fecha_de_registro) AS dias_desde_ingreso,
    usuario.deuda
   FROM ((public.usuario
     JOIN ( SELECT q1.num_cel_u,
            count(q1.coords_inicial) AS cuenta
           FROM ( SELECT usuario_1.num_cel_u,
                    carrera.coords_inicial
                   FROM (public.carrera
                     RIGHT JOIN public.usuario usuario_1 ON (((usuario_1.num_cel_u)::text = (carrera.num_cel_u)::text)))) q1
          GROUP BY q1.num_cel_u) q2 USING (num_cel_u))
     JOIN ( SELECT q1.num_cel_u,
            COALESCE(sum(((1.609344)::double precision * (q1.coords_inicial OPERATOR(public.<@>) q1.coords_final))), (0)::double precision) AS distancia
           FROM ( SELECT usuario_1.num_cel_u,
                    carrera.coords_inicial,
                    carrera.coords_final
                   FROM (public.carrera
                     RIGHT JOIN public.usuario usuario_1 ON (((usuario_1.num_cel_u)::text = (carrera.num_cel_u)::text)))) q1
          GROUP BY q1.num_cel_u) q3 USING (num_cel_u))
  WHERE ((usuario.num_cel_u)::text = (usuario.num_cel_u)::text);


ALTER TABLE public.perfiles_usuarios OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 123314)
-- Name: puntaje_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.puntaje_log (
    id_taxista character varying(20) NOT NULL,
    acomulado bigint
);


ALTER TABLE public.puntaje_log OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 123503)
-- Name: registro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.registro (
    placa character varying(20) NOT NULL,
    id_taxista character varying(20) NOT NULL,
    entrada_turno timestamp with time zone NOT NULL,
    salida_turno timestamp with time zone
);


ALTER TABLE public.registro OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 106642)
-- Name: reporte; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reporte (
    placa character varying(20) NOT NULL,
    id_taxista character varying(20) NOT NULL,
    coords_gps_r point NOT NULL,
    fecha_r timestamp with time zone NOT NULL,
    estado boolean NOT NULL
);


ALTER TABLE public.reporte OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 114851)
-- Name: tarifa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tarifa (
    id_tarifa integer NOT NULL,
    costo double precision NOT NULL,
    horario_desde time(0) without time zone,
    horario_hasta time(0) without time zone
);


ALTER TABLE public.tarifa OWNER TO postgres;

--
-- TOC entry 203 (class 1259 OID 114849)
-- Name: tarifa_id_tarifa_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tarifa_id_tarifa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tarifa_id_tarifa_seq OWNER TO postgres;

--
-- TOC entry 3048 (class 0 OID 0)
-- Dependencies: 203
-- Name: tarifa_id_tarifa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tarifa_id_tarifa_seq OWNED BY public.tarifa.id_tarifa;


--
-- TOC entry 199 (class 1259 OID 81920)
-- Name: taxi; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.taxi (
    placa character varying(20) NOT NULL,
    baul character varying(50) NOT NULL,
    soat character varying(50) NOT NULL,
    modelo character varying(50) NOT NULL,
    marca character varying(50) NOT NULL,
    year integer NOT NULL,
    fecha_de_adquisicion timestamp(0) with time zone,
    CONSTRAINT taxi_year_check CHECK (((year > 1900) AND (year < 10000)))
);


ALTER TABLE public.taxi OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 123335)
-- Name: taxistas_en_servicio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.taxistas_en_servicio (
    id_taxista character varying(20) NOT NULL,
    placa character varying(20) NOT NULL,
    coordenadas point NOT NULL,
    estado boolean NOT NULL
);


ALTER TABLE public.taxistas_en_servicio OWNER TO postgres;

--
-- TOC entry 2824 (class 2604 OID 147979)
-- Name: dir_fav id_dir_fav; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dir_fav ALTER COLUMN id_dir_fav SET DEFAULT nextval('public.dir_fav_id_dir_fav_seq'::regclass);


--
-- TOC entry 2825 (class 2604 OID 114854)
-- Name: tarifa id_tarifa; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarifa ALTER COLUMN id_tarifa SET DEFAULT nextval('public.tarifa_id_tarifa_seq'::regclass);


--
-- TOC entry 3024 (class 0 OID 123213)
-- Dependencies: 205
-- Data for Name: carrera; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10000', '2019-10-22 08:00:00+00', '(3.3800490000000001,-76.536051999999998)', '(3.382234,-76.537919000000002)', false, '2019-03-23 19:03:27+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'CCC222', '10000', '2019-10-23 08:00:00+00', '(3.3800490000000001,-76.536051999999998)', '(3.382234,-76.537919000000002)', false, '2019-03-23 19:03:27+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'AAA111', '1234', '2019-10-21 08:00:00+00', '(3.3800490000000001,-76.536051999999998)', '(3.382234,-76.537919000000002)', false, '2019-03-23 19:03:27+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434509', 1, 'GGG222', '10003', '2019-10-24 08:00:00+00', '(3.3800490000000001,-76.536051999999998)', '(3.354117,-76.528416000000007)', false, '2019-03-23 19:03:27+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434509', 1, 'AAA111', '10002', '2019-03-11 13:00:00+00', '(3.3800490000000001,-76.536051999999998)', '(3.354117,-76.528416000000007)', true, '2019-03-23 19:03:27+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434509', 1, 'AAA111', '10002', '2019-10-23 08:00:00+00', '(3.3800490000000001,-76.536051999999998)', '(3.382234,-76.837918999999999)', true, '2019-03-23 19:03:27+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434509', 1, 'AAA111', '10000', '2019-03-13 20:54:56+00', '(3.3800490000000001,-76.536051999999998)', '(3.382234,-76.537919000000002)', false, '2019-03-23 19:03:27+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434500', 1, 'AAA111', '1234', '2019-03-23 19:07:23+00', '(3.3800490000000001,-76.536051999999998)', '(3.3330060000000001,-76.536201000000005)', false, '2019-03-23 19:54:35+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434500', 1, 'AAA111', '1234', '2019-03-24 17:57:56+00', '(3.3800490000000001,-76.536051999999998)', '(3.3330060000000001,-76.536201000000005)', false, '2019-03-24 18:08:54+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434500', 1, 'AAA111', '1234', '2019-03-31 22:56:32+00', '(3.3800490000000001,-76.536051999999998)', '(3.3330060000000001,-76.536201000000005)', false, '2019-03-31 22:58:30+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434500', 1, 'AAA111', '205', '2019-03-31 23:01:38+00', '(3.3800490000000001,-76.536051999999998)', '(3.3330060000000001,-76.536201000000005)', false, '2019-03-31 23:02:04+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3107434507', 1, 'AAA111', '205', '2019-03-31 23:03:02+00', '(3.3800490000000001,-76.536051999999998)', '(3.3330060000000001,-76.536201000000005)', false, '2019-03-31 23:03:10+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'DDD222', '10007', '2019-04-01 06:38:02+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', false, '2019-04-01 16:05:26+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-03-30 21:01:24+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-03-30 22:33:13+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-03-30 22:39:20+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 16:05:26+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 16:08:41+00', '(3.3330060000000001,-76.536201000000005)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 16:20:59+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 16:30:15+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 17:16:48+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 18:45:20+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 18:45:27+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 17:18:07+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 17:20:07+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 18:37:48+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 18:37:51+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 18:47:27+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 18:47:30+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 18:39:49+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 18:39:52+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 18:40:38+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 18:40:40+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434508', 1, 'AAA111', '1234', '2019-03-17 23:08:27+00', '(3.3800490000000001,-76.536051999999998)', '(3.382234,-76.537919000000002)', false, '2019-03-17 23:11:29+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434500', 1, 'AAA111', '1234', '2019-03-17 23:25:03+00', '(3.3800490000000001,-76.536051999999998)', '(3.382234,-76.537919000000002)', false, '2019-03-17 23:26:07+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434500', 1, 'AAA111', '1234', '2019-03-17 23:30:39+00', '(3.3800490000000001,-76.536051999999998)', '(3.382234,-76.537919000000002)', false, '2019-03-17 23:30:44+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434500', 1, 'AAA111', '1234', '2019-03-17 23:32:01+00', '(3.3800490000000001,-76.536051999999998)', '(3.382234,-76.537919000000002)', false, '2019-03-17 23:32:15+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434509', 1, 'AAA111', '1234', '2019-03-17 20:52:40+00', '(3.3800490000000001,-76.536051999999998)', '(3.382234,-76.537919000000002)', false, '2019-03-17 21:19:03+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434509', 1, 'AAA111', '1234', '2019-03-17 22:13:06+00', '(3.3800490000000001,-76.536051999999998)', '(3.382234,-76.537919000000002)', false, '2019-03-17 22:13:12+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 18:42:04+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 18:42:09+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 18:44:30+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 18:44:38+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:05:19+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-02 03:05:24+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 18:49:57+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 18:49:59+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 18:51:34+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 18:51:36+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:24:47+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', false, '2019-04-02 03:24:49+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 18:54:23+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 18:54:25+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:26:12+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', false, '2019-04-02 03:26:14+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 18:55:30+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 18:55:31+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:33:55+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', false, '2019-04-02 03:33:57+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 18:59:10+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 19:07:34+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:35:06+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', false, '2019-04-02 03:35:08+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 19:07:55+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 19:08:07+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:40:45+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', false, '2019-04-02 03:40:47+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 20:06:55+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 20:07:08+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:42:12+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', false, '2019-04-02 03:42:14+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-01 21:54:02+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-01 21:54:08+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:45:20+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', false, '2019-04-02 03:45:22+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:09:56+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-02 03:09:59+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:46:50+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', false, '2019-04-02 03:46:52+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:15:09+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-02 03:15:10+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:50:26+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', false, '2019-04-02 03:50:28+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'BBB222', '10004', '2019-04-02 03:21:56+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-02 03:21:58+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'EEE222', '10008', '2019-04-02 04:05:14+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-02 04:05:25+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'EEE222', '10008', '2019-04-02 04:06:32+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-02 04:06:34+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'EEE222', '10008', '2019-04-03 04:36:04+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-03 04:36:08+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('Deleted User', 1, 'EEE222', '10008', '2019-04-04 20:21:49+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-04 20:21:58+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('Deleted User', 1, 'EEE222', '10008', '2019-04-05 00:53:17+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-05 00:53:19+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'EEE222', '10008', '2019-04-06 04:34:26+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-06 04:35:53+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'EEE222', '10008', '2019-04-06 07:48:28+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-06 07:48:32+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3107434507', 1, 'AAA111', '205', '2019-04-01 16:20:38+00', '(3.3800490000000001,-76.536051999999998)', '(3.3330060000000001,-76.536201000000005)', false, '2019-04-06 17:09:42+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'EEE222', '10008', '2019-04-06 17:39:43+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-06 17:40:07+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'EEE222', '10008', '2019-04-06 19:42:56+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-06 19:58:03+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'EEE222', '10008', '2019-04-06 20:10:41+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-06 20:10:44+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'EEE222', '10008', '2019-04-06 20:15:11+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-06 20:15:16+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'EEE222', '10008', '2019-04-06 20:19:36+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-06 20:19:38+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'EEE222', '10008', '2019-04-06 21:05:23+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', false, '2019-04-06 21:05:31+00');
INSERT INTO public.carrera (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera, coords_inicial, coords_final, califico, fecha_fin_carrera) VALUES ('3167434506', 1, 'EEE222', '10008', '2019-04-06 20:20:38+00', '(3.382234,-76.537909999999997)', '(3.3330060000000001,-76.536201000000005)', true, '2019-04-06 20:20:40+00');


--
-- TOC entry 3028 (class 0 OID 131559)
-- Dependencies: 211
-- Data for Name: carreras_en_curso; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3020 (class 0 OID 106620)
-- Dependencies: 201
-- Data for Name: dir_fav; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167434506', 'Colegio', '(3.3585889999999998,-76.527508999999995)', '2019-04-03 04:58:04+00', 4);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167434506', 'Trabajo', '(3.374072,-76.532416999999995)', '2019-04-03 04:58:04+00', 1);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167434506', 'Casa', '(3.356589,-76.528509)', '2019-04-03 04:58:04+00', 2);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167434506', 'Universidad', '(3.356589,-76.527508999999995)', '2019-04-03 04:58:04+00', 3);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430020', 'pto trancon', '(3.3637576817484129,-76.531933307778672)', '2019-04-04 22:24:32+00', 5);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'Casa', '(3.3535892999999999,-76.527641299999999)', '2019-04-05 17:37:49+00', 6);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'oguo', '(3.3535934999999997,-76.527637099999993)', '2019-04-05 17:40:44+00', 7);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'agua', '(3.3535934999999997,-76.527637099999993)', '2019-04-05 17:40:56+00', 8);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'GG', '(3.3535934999999997,-76.527637099999993)', '2019-04-05 17:42:09+00', 9);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'Haga', '(3.3535934999999997,-76.527637099999993)', '2019-04-05 17:44:35+00', 10);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'sevi', '(3.3535934999999997,-76.527637099999993)', '2019-04-05 17:47:45+00', 11);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'llana', '(3.3535934999999997,-76.527637099999993)', '2019-04-05 17:48:02+00', 12);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'miche', '(3.3535934999999997,-76.527637099999993)', '2019-04-05 17:49:52+00', 13);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'hehe', '(-76.5276602,3.3536039)', '2019-04-05 18:00:30+00', 14);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'hehe XD', '(-76.52764599999999,3.3535925999999998)', '2019-04-05 18:17:51+00', 15);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'plz', '(-76.52764599999999,3.3535925999999998)', '2019-04-05 18:20:17+00', 16);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'kisek', '(-76.52764599999999,3.3535925999999998)', '2019-04-05 18:22:09+00', 17);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'kiseki', '(-76.52764599999999,3.3535925999999998)', '2019-04-05 18:22:13+00', 18);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'testo', '(-76.52764599999999,3.3535925999999998)', '2019-04-05 18:28:48+00', 19);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'testos', '(-76.52764599999999,3.3535925999999998)', '2019-04-05 18:30:47+00', 20);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'testoss', '(-76.52764599999999,3.3535925999999998)', '2019-04-05 18:35:26+00', 21);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':V', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 18:41:44+00', 22);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':VV', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 18:46:49+00', 23);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':VVV', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 18:48:51+00', 24);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':VVVv', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 18:49:13+00', 25);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':VVVvV', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 18:49:41+00', 26);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':VVVvVV', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 18:50:03+00', 27);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':VVVvVVv', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 18:50:50+00', 28);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':VVVvVVvV', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 18:52:43+00', 29);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':VVVvVVvVV', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 18:53:16+00', 30);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':VVVvVVvVVv', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 18:53:45+00', 31);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':VVVvVVvVVvV', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 18:55:23+00', 32);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':VVVvVVvVVvVv', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 18:56:25+00', 33);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':VVVvVVvVVvVvV', '(-76.527659200000002,3.3535781999999998)', '2019-04-05 19:06:48+00', 34);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':v', '(-76.527656700000009,3.3535865)', '2019-04-05 19:07:37+00', 35);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', ':vv', '(-76.527656700000009,3.3535865)', '2019-04-05 19:11:55+00', 36);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'eks di :VVVV', '(-76.52764599999999,3.3535824999999999)', '2019-04-05 19:42:29+00', 37);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'eks di :VVVVv', '(-76.52764599999999,3.3535824999999999)', '2019-04-05 19:47:53+00', 38);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'eks di :VVVVvV', '(-76.52764599999999,3.3535824999999999)', '2019-04-05 19:48:26+00', 39);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'eks di :VVVVvVv', '(-76.531036378000877,3.3525203158088877)', '2019-04-05 19:59:28+00', 40);
INSERT INTO public.dir_fav (num_cel_u, nombre_dir, coords_gps_u, fecha_de_registro, id_dir_fav) VALUES ('3167430010', 'eks di :VVVVvVvsz', '(-76.552150727366097,3.3520062128707981)', '2019-04-05 21:54:38+00', 41);


--
-- TOC entry 3025 (class 0 OID 123314)
-- Dependencies: 207
-- Data for Name: puntaje_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.puntaje_log (id_taxista, acomulado) VALUES ('10002', 9);
INSERT INTO public.puntaje_log (id_taxista, acomulado) VALUES ('10004', 120);
INSERT INTO public.puntaje_log (id_taxista, acomulado) VALUES ('10008', 62);


--
-- TOC entry 3027 (class 0 OID 123503)
-- Dependencies: 210
-- Data for Name: registro; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.registro (placa, id_taxista, entrada_turno, salida_turno) VALUES ('BBB222', '10000', '2019-03-13 20:16:24+00', NULL);
INSERT INTO public.registro (placa, id_taxista, entrada_turno, salida_turno) VALUES ('BBB222', '10005', '2019-03-17 22:28:35+00', '2019-03-17 22:45:23+00');
INSERT INTO public.registro (placa, id_taxista, entrada_turno, salida_turno) VALUES ('BBB222', '10005', '2019-03-17 22:45:43+00', '2019-03-17 22:45:50+00');
INSERT INTO public.registro (placa, id_taxista, entrada_turno, salida_turno) VALUES ('BBB222', '10005', '2019-03-17 22:45:59+00', '2019-03-17 22:46:36+00');
INSERT INTO public.registro (placa, id_taxista, entrada_turno, salida_turno) VALUES ('BBB222', '10004', '2019-03-30 05:03:06+00', NULL);
INSERT INTO public.registro (placa, id_taxista, entrada_turno, salida_turno) VALUES ('DDD222', '10007', '2019-04-01 06:30:15+00', '2019-04-01 06:31:01+00');
INSERT INTO public.registro (placa, id_taxista, entrada_turno, salida_turno) VALUES ('DDD222', '10007', '2019-04-01 06:31:19+00', NULL);
INSERT INTO public.registro (placa, id_taxista, entrada_turno, salida_turno) VALUES ('EEE222', '10008', '2019-04-02 04:03:05+00', NULL);
INSERT INTO public.registro (placa, id_taxista, entrada_turno, salida_turno) VALUES ('HHH222', '10000', '2019-04-03 01:26:47+00', NULL);
INSERT INTO public.registro (placa, id_taxista, entrada_turno, salida_turno) VALUES ('JJJ222', '10001', '2019-04-03 03:04:44+00', NULL);
INSERT INTO public.registro (placa, id_taxista, entrada_turno, salida_turno) VALUES ('CCC222', '10005', '2019-03-31 01:00:37+00', '2019-04-06 17:07:12+00');
INSERT INTO public.registro (placa, id_taxista, entrada_turno, salida_turno) VALUES ('KKK222', '10005', '2019-04-06 22:46:21+00', NULL);


--
-- TOC entry 3021 (class 0 OID 106642)
-- Dependencies: 202
-- Data for Name: reporte; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-10 19:35:24+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-10 19:35:24+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-10 19:35:24+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-10 19:35:24+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-10 19:35:24+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-10 19:35:24+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-10 19:35:24+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-10 19:35:24+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-10 19:35:24+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-10 19:35:24+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-10 19:35:24+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-11 01:43:03+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-11 01:43:03+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-11 01:43:03+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-11 01:43:03+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-11 01:43:03+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-11 01:43:03+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-11 01:43:03+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-11 01:43:03+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-11 01:43:03+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-11 01:43:03+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-11 01:43:03+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-11 01:53:20+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-11 01:53:20+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-11 01:53:20+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-11 01:53:20+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-11 01:53:20+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-11 01:53:20+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-11 01:53:20+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-11 01:53:20+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-11 01:53:20+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-11 01:53:20+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-11 01:53:20+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-11 01:53:43+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-11 01:53:43+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-11 01:53:43+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-11 01:53:43+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-11 01:53:43+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-11 01:53:43+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-11 01:53:43+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-11 01:53:43+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-11 01:53:43+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-11 01:53:43+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-11 01:53:43+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-11 02:14:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-11 02:14:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-11 02:14:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-11 02:14:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-11 02:14:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-11 02:14:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-10 23:30:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-10 23:30:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-10 23:30:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-10 23:30:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-10 23:30:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-10 23:30:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-10 23:30:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-10 23:30:00+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-10 23:30:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-10 23:30:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-10 23:30:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-10 23:50:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-10 23:50:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-10 23:50:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-10 23:50:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-10 23:50:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-10 23:50:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-10 23:50:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-10 23:50:00+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-10 23:50:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-10 23:50:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-10 23:50:00+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-11 02:14:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-11 02:14:15+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-11 02:14:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-11 02:14:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-11 02:14:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-11 02:15:01+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-11 02:15:01+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-11 02:15:01+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-11 02:15:01+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-11 02:15:01+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-11 02:15:01+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-11 02:15:01+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-11 02:15:01+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-11 02:15:01+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-11 02:15:01+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-11 02:15:01+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-11 02:15:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-11 02:15:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-11 02:15:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-11 02:15:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-11 02:15:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-11 02:15:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-11 02:15:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-11 02:15:15+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-11 02:15:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-11 02:15:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-11 02:15:15+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-11 02:20:12+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-11 02:20:12+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-11 02:20:12+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-11 02:20:12+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-11 02:20:12+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-11 02:20:12+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-11 02:20:12+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-11 02:20:12+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-11 02:20:12+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-11 02:20:12+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-11 02:20:12+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-11 19:01:45+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-11 19:01:45+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-11 19:01:45+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-11 19:01:45+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-11 19:01:45+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-11 19:01:45+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-11 19:01:45+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-11 19:01:45+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-11 19:01:45+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-11 19:01:45+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-11 19:01:45+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-13 01:50:59+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-13 01:50:59+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-13 01:50:59+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-13 01:50:59+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-13 01:50:59+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-13 01:50:59+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-13 01:50:59+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-13 01:50:59+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-13 01:50:59+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-13 01:50:59+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-13 01:50:59+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('BBB222', '10001', '(3.3800490000000001,-76.536051999999998)', '2019-03-13 02:00:31+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('CCC222', '10002', '(3.382234,-76.537919000000002)', '2019-03-13 02:00:31+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('DDD222', '10003', '(3.3805100000000001,-76.526545999999996)', '2019-03-13 02:00:31+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('EEE222', '10004', '(3.3541189999999999,-76.528362999999999)', '2019-03-13 02:00:31+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('FFF222', '10005', '(3.3761749999999999,-76.567758999999995)', '2019-03-13 02:00:31+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('GGG222', '10006', '(3.5366089999999999,-76.388279999999995)', '2019-03-13 02:00:31+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('HHH222', '10007', '(3.494418,-76.521842000000007)', '2019-03-13 02:00:31+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('III222', '10008', '(3.3686820000000002,-76.529019000000005)', '2019-03-13 02:00:31+00', true);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('JJJ222', '10009', '(3.37338,-76.532915000000003)', '2019-03-13 02:00:31+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('KKK222', '10010', '(3.4504429999999999,-76.479223000000005)', '2019-03-13 02:00:31+00', false);
INSERT INTO public.reporte (placa, id_taxista, coords_gps_r, fecha_r, estado) VALUES ('LLL222', '10011', '(3.3881070000000002,-76.513551000000007)', '2019-03-13 02:00:31+00', false);


--
-- TOC entry 3023 (class 0 OID 114851)
-- Dependencies: 204
-- Data for Name: tarifa; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tarifa (id_tarifa, costo, horario_desde, horario_hasta) VALUES (1, 1000, '08:00:00', '12:00:00');
INSERT INTO public.tarifa (id_tarifa, costo, horario_desde, horario_hasta) VALUES (2, 1200, '01:00:00', '07:59:00');


--
-- TOC entry 3018 (class 0 OID 81920)
-- Dependencies: 199
-- Data for Name: taxi; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('AAA111', 'Grande', '12345', 'Picanto', 'KIA', 2019, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('BBB222', 'Grande', '123456', 'Spark', 'Chevrolet', 2019, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('CCC222', 'Grande', '10000', 'Spark', 'Chevrolet', 2017, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('DDD222', 'Mediano', '10001', 'Spark', 'Chevrolet', 2018, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('EEE222', 'Mediano', '10001', 'Picanto', 'KIA', 2018, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('FFF222', 'Grande', '10003', 'Picanto', 'KIA', 2015, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('GGG222', 'Pequeño', '10004', 'Logan', 'Renault', 2014, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('HHH222', 'Pequeño', '10005', 'Logan', 'Renault', 2014, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('III222', 'Pequeño', '10006', 'Logan', 'Renault', 2014, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('JJJ222', 'Grande', '10007', '3', 'Mazda', 2019, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('KKK222', 'Grande', '10008', '3', 'Mazda', 2019, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('LLL222', 'Grande', '10009', '3', 'Mazda', 2019, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('MMM222', 'Mediano', '10010', '508', 'peugeot', 2019, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('NNN222', 'Mediano', '10011', '508', 'peugeot', 2019, NULL);
INSERT INTO public.taxi (placa, baul, soat, modelo, marca, year, fecha_de_adquisicion) VALUES ('ABC123', 'Grande', '0123456789', 'Logan', 'Renault', 2018, '2019-04-02 04:14:25+00');


--
-- TOC entry 3019 (class 0 OID 81925)
-- Dependencies: 200
-- Data for Name: taxista; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10004', 'Alvaro', 'Santos', 5, '3167430004', 24739.246051089871, 'Hello world', '10004', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10008', 'Eduardo', 'Uribe', 4.7692307692307692, '3167430008', 11596.521586448382, 'Hello world', '10008', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('1234', 'Camilo', 'Velez', 0, '3167434501', 1143.6919868405018, 'hola mundo', '1234', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('666', 'Cuello', 'Loco', 0, '3167439018', 0, '$2a$10$UITC9DhEqnS8.scGCO/qG.IVXqCkHVTTCgMnVZjWVN5ZndPhFE8fq', '$2a$10$D4p/4vu98tGQmPGsg/aE9.KpkfkDbC5OmFDBTD2JEf0wPgG0sBiLe', '2019-04-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('420', 'Miguel', 'Sevilla', 0, '3160202736', 0, '$2a$10$qwCFEteRIW86aJv1hYyKKuJ8p7Rh9.3iwerGxg4QW7.OwhOydgvTG', '$2a$10$/db0ywR3EC1o5y9UvYoJUeSgsgIDKoAPN9Sh4zuagpJszUd7okiyS', '2019-04-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10007', 'Karla', 'Vargas', 0, '3167430007', 773.10143909655869, 'Hello world', '10007', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10001', 'Camilo', 'Popo', 0, '3167430001', 0, 'Hello world', '10001', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10005', 'Gustavo', 'Petro', 0, '3167430005', 0, 'Hello world', '10005', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10006', 'IVAn', 'Duque', 0, '3167430006', 0, 'Hello world', '10006', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10009', 'Miguel', 'Reyes', 0, '3167430009', 0, 'Hello world', '10009', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10010', 'Andres', 'Gutierrez', 0, '3167430010', 0, 'Hello world', '10010', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10011', 'Ayuwoki', 'Eoo', 0, '3167430011', 0, 'Hello world', '10011', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10012', 'Ricardo', 'Milos', 0, '3167430012', 0, 'Hello world', '10012', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10013', 'Momo', 'Kaguya', 0, '3167430013', 0, 'Hello world', '10013', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10014', 'Daniela', 'Corredor', 0, '3167430013', 0, 'Hello world', '10014', '2019-03-16');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10015', 'Daniel', 'Corredor', 0, '3167430015', 0, 'Hello world', '10015', '2019-03-17');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10016', 'Alejandro', 'Pardo', 0, '3167430016', 0, '$2a$10$HwnPmr.736USvCeY8p902uPmF.JE/s9znKwML.ImeichCp0KRoJg6', '$2a$10$gW51rqaYEBbO56bmpJIasuH96eiS7sqLBKtMN9JeNRU2f2zNzhzqq', '2019-03-17');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('69', 'Alvaro', 'Uribe', 0, '3167430025', 0, '$2a$10$05DakpNEUOQEm5wjAftwWevMR/ENL3Kq0HTBpek95wDPxkGL9eKti', '$2a$10$JH46pEgwl4USFBCuWYiQq.nCs9XuMuXUP3zIyEqA/Ae7/1TwS54xm', '2019-04-06');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('205', 'David', 'Gaona', 0, '3167430021', 2192.4758940062534, '$2a$10$QNx7v.6ZHDL/krvLUbVvouDpBJcxhaOHAGTg.crbWBwUojwI7GeLa', '$2a$10$A6uIDnX7rDaSpSAnL1XtzORLvzEgulo2/WOfnvjk4mQHiX1YiPxwS', '2019-03-24');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10003', 'Daniel', 'Cuevas', 0, '3167430003', 650.18590218680663, 'Hello world', '10003', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10002', 'Andrea', 'Plaza', 4.5, '3167430002', 20809.959399611445, 'Hello world', '10002', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10000', 'Camilo', 'Perez', 0, '3167430000', 387.69117560992834, 'Hello world', '10000', '2019-03-01');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('10017', 'Cristian', 'Pascumal', 0, '3167430017', 0, '$2a$10$HwnPmr.736USvCeY8p902uPmF.JE/s9znKwML.ImeichCp0KRoJg6', '$2a$10$gW51rqaYEBbO56bmpJIasuH96eiS7sqLBKtMN9JeNRU2f2zNzhzqq', '2019-03-23');
INSERT INTO public.taxista (id_taxista, nombre_t, apellido_t, puntaje, num_cel_t, saldo, password_t, num_cuenta, fecha_de_ingreso) VALUES ('1123123123', 'test', 'prueba', 0, '3167430018', 0, '$2a$10$zdltRevPUvOlcL4S0.mdaeWc/7oEaGlnY2sCLCc9.dSfQaTPJHXje', '$2a$10$I4CEde4Ru3ugndNXf1djJeMPkKQXgcSBapD2ALCWhVbJkAq3LhNxu', '2019-03-23');


--
-- TOC entry 3026 (class 0 OID 123335)
-- Dependencies: 209
-- Data for Name: taxistas_en_servicio; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.taxistas_en_servicio (id_taxista, placa, coordenadas, estado) VALUES ('10005', 'KKK222', '(-76.494219999999999,3.495736)', true);
INSERT INTO public.taxistas_en_servicio (id_taxista, placa, coordenadas, estado) VALUES ('10004', 'BBB222', '(3.382234,-76.537909999999997)', true);
INSERT INTO public.taxistas_en_servicio (id_taxista, placa, coordenadas, estado) VALUES ('10000', 'HHH222', '(-76.526545999999996,3.3805100000000001)', true);
INSERT INTO public.taxistas_en_servicio (id_taxista, placa, coordenadas, estado) VALUES ('10001', 'JJJ222', '(-76.526545999999996,3.3805100000000001)', true);
INSERT INTO public.taxistas_en_servicio (id_taxista, placa, coordenadas, estado) VALUES ('1234', 'AAA111', '(3.382234,-76.537919000000002)', true);
INSERT INTO public.taxistas_en_servicio (id_taxista, placa, coordenadas, estado) VALUES ('10007', 'DDD222', '(3.382234,-76.537909999999997)', false);
INSERT INTO public.taxistas_en_servicio (id_taxista, placa, coordenadas, estado) VALUES ('10008', 'EEE222', '(3.382234,-76.537909999999997)', true);


--
-- TOC entry 3017 (class 0 OID 74041)
-- Dependencies: 198
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('3167430010', 'oguo', 'egue', '$2a$10$aYD/PIGmd2YChUoJdHquvOG8c9NmRoPY.J5s3j9hqiSmuKL.6o6iy', '$2a$10$hrxQ5FpLEpuHL3je2.BqteXezuIQCAJwk.6Eoy8X/j6W/a4ZevOLu', 0, '2019-03-27');
INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('3167434509', 'Alex', 'Gomez', '$2a$10$AE.BIa3Y.fgrCLfRGVWB.OVxn/5xTBZ3YKCyn9aRN1fDuUD0QhZi.', '$2a$10$621bNCmXOzPli2JYSTWiEuddeolKmHxSatATypKGW58dQJUpiHtOi', 35982.723160415648, '2019-03-01');
INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('3107434507', 'E', 'O', '$2a$10$ku7sEIlZLVY1Vedn0nKmVO7Ad1.d3d0lIf8loNDnDtmSxRJMmF9AG', '$2a$10$KXZxSF4Qo5ngDgvl3o1AHO.FiHn7kEtUcy/l7yVyLZD78OYh0CcBm', 2436.0843266736151, '2019-03-16');
INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('3167434500', 'Ayu', 'Woki', ':V', 'misterio', 2436.7298331265119, '2019-03-16');
INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('"3107432020"', '"Maria"', '"Medina"', '$2a$10$5JjH6lE4yVtJkkDm5NRWnO99lXJUVacPjdFAWqpgLPZcPkQaRXphu', '$2a$10$fute3epJa8F2XH5O6CqL1.DRZhazi2iqU3EY44J68xRdXLDb/l6Z.', 0, '2019-03-17');
INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('3167434506', 'Diana', 'Sevillana', '$2a$10$vVNyk5wvaEhWcqTSnWghHu075Id3C8nKX8iEs3ixkBAO89B7X3u9G', '$2a$10$uVNZfZx/98NbM23ZrsmYXOeuaH1XfDOxfANiaTG7X2HH5xm92KQsa', 59100.196040300099, '2019-03-01');
INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('3167434508', 'Sevi', 'Llana', '$2a$10$AE.BIa3Y.fgrCLfRGVWB.OVxn/5xTBZ3YKCyn9aRN1fDuUD0QhZi.', '$2a$10$621bNCmXOzPli2JYSTWiEuddeolKmHxSatATypKGW58dQJUpiHtOi', 0.21516881763232784, '2019-03-10');
INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('3160000000', 'Alex Sander', 'Gomez', '$2a$10$a2UakZrSBMhApJCfOnDt/e5g.A9htO05i8LCJt210oVK.ywC.n4F6', '$2a$10$o1erzZCnJ0edYP8PF/1OgO2i0bnSZZYetBUKAz3sUde2E2QipG4Fm', 0, '2019-04-02');
INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('3107434508', 'Miche', 'Lin', '$2a$10$ybpWuzt17aoGK1nDnKdYpOEqnOKhvDIV7q2lL9eIh/sw37NGOsEfG', '$2a$10$mZkhnIBSLLSaP6altlaWiuhGA/D0UeN4H.OgV4VttB0SIrxXjVne6', 0, '2019-03-23');
INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('3167430019', 'David', 'Gaona', '$2a$10$SFkFmkfzmw98wChtDoSMRemGmxKKkn2XTnJh.5HWzUZkfTW.ZiKYO', '$2a$10$AkeJF6PXQgfA3hLQgfnEpOelzgFX97/8VzlToQESv8p3dLXwyh70S', 0, '2019-03-24');
INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('3167430020', 'Miguel', 'Reyes', '$2a$10$1hQ1SzQem0nvOjite4aoM.pV1TSv4ma.YFy.T0Omk9UaO2a2Mjygm', '$2a$10$A6cCCvNyiCHDGAjEy2Nb0uUJNzzUqSAu3K/2ASltWT7L0tLhKPbEu', 0, '2019-03-24');
INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('Deleted User', '', '', '$2a$10$ybpWuzt17aoGK1nDnKdYpOEqnOKhvDIV7q2lL9eIh/sw37NGOsEfG', '$2a$10$mZkhnIBSLLSaP6altlaWiuhGA/D0UeN4H.OgV4VttB0SIrxXjVne6', 0, '2000-01-01');
INSERT INTO public.usuario (num_cel_u, nombre_u, apellido_u, tarjeta_credito, password, deuda, fecha_de_registro) VALUES ('5555555555', 'Momo', 'Lin', '$2a$10$odcBDhwnIA8NQS3bDlFk.uto8eqQvj8ffWqB4HZ0/pqIyMaJNTTQm', '$2a$10$IzICIdFzFnr.mt4SbdPUZ.ObbcZqiM4XwMrqxM35AVU2mgR7uDzBS', 0, '2019-04-05');


--
-- TOC entry 3051 (class 0 OID 0)
-- Dependencies: 212
-- Name: dir_fav_id_dir_fav_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.dir_fav_id_dir_fav_seq', 41, true);


--
-- TOC entry 3052 (class 0 OID 0)
-- Dependencies: 203
-- Name: tarifa_id_tarifa_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tarifa_id_tarifa_seq', 2, true);


--
-- TOC entry 2859 (class 2606 OID 123507)
-- Name: registro PK_registro; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registro
    ADD CONSTRAINT "PK_registro" PRIMARY KEY (placa, id_taxista, entrada_turno);


--
-- TOC entry 2841 (class 2606 OID 123217)
-- Name: carrera carrera_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carrera
    ADD CONSTRAINT carrera_pkey PRIMARY KEY (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera);


--
-- TOC entry 2861 (class 2606 OID 131563)
-- Name: carreras_en_curso carreras_en_curso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras_en_curso
    ADD CONSTRAINT carreras_en_curso_pkey PRIMARY KEY (num_cel_u, id_tarifa, placa, id_taxista, fecha_carrera);


--
-- TOC entry 2833 (class 2606 OID 147988)
-- Name: dir_fav dir_fav_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dir_fav
    ADD CONSTRAINT dir_fav_pkey PRIMARY KEY (id_dir_fav);


--
-- TOC entry 2837 (class 2606 OID 106646)
-- Name: reporte pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reporte
    ADD CONSTRAINT pk PRIMARY KEY (placa, id_taxista, fecha_r);


--
-- TOC entry 2851 (class 2606 OID 123318)
-- Name: puntaje_log puntaje_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.puntaje_log
    ADD CONSTRAINT puntaje_log_pkey PRIMARY KEY (id_taxista);


--
-- TOC entry 2839 (class 2606 OID 114856)
-- Name: tarifa tarifa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarifa
    ADD CONSTRAINT tarifa_pkey PRIMARY KEY (id_tarifa);


--
-- TOC entry 2829 (class 2606 OID 81942)
-- Name: taxi taxi_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.taxi
    ADD CONSTRAINT taxi_pkey PRIMARY KEY (placa);


--
-- TOC entry 2831 (class 2606 OID 123042)
-- Name: taxista taxista_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.taxista
    ADD CONSTRAINT taxista_pkey PRIMARY KEY (id_taxista);


--
-- TOC entry 2853 (class 2606 OID 123339)
-- Name: taxistas_en_servicio taxistas_disponibles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.taxistas_en_servicio
    ADD CONSTRAINT taxistas_disponibles_pkey PRIMARY KEY (id_taxista, placa);


--
-- TOC entry 2835 (class 2606 OID 148021)
-- Name: dir_fav unique_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dir_fav
    ADD CONSTRAINT unique_name UNIQUE (num_cel_u, nombre_dir);


--
-- TOC entry 2843 (class 2606 OID 123411)
-- Name: carrera unique_taxi_carrera; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carrera
    ADD CONSTRAINT unique_taxi_carrera UNIQUE (placa, fecha_carrera);


--
-- TOC entry 2863 (class 2606 OID 131565)
-- Name: carreras_en_curso unique_taxi_carreras; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras_en_curso
    ADD CONSTRAINT unique_taxi_carreras UNIQUE (placa, fecha_carrera);


--
-- TOC entry 2855 (class 2606 OID 123485)
-- Name: taxistas_en_servicio unique_taxi_disponible; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.taxistas_en_servicio
    ADD CONSTRAINT unique_taxi_disponible UNIQUE (placa);


--
-- TOC entry 2845 (class 2606 OID 123413)
-- Name: carrera unique_taxista_carrera; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carrera
    ADD CONSTRAINT unique_taxista_carrera UNIQUE (id_taxista, fecha_carrera);


--
-- TOC entry 2865 (class 2606 OID 131567)
-- Name: carreras_en_curso unique_taxista_carreras; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras_en_curso
    ADD CONSTRAINT unique_taxista_carreras UNIQUE (id_taxista, fecha_carrera);


--
-- TOC entry 2857 (class 2606 OID 123487)
-- Name: taxistas_en_servicio unique_taxista_disponible; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.taxistas_en_servicio
    ADD CONSTRAINT unique_taxista_disponible UNIQUE (id_taxista);


--
-- TOC entry 2847 (class 2606 OID 131550)
-- Name: carrera unique_todos; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carrera
    ADD CONSTRAINT unique_todos UNIQUE (placa, id_taxista, fecha_carrera, num_cel_u);


--
-- TOC entry 2867 (class 2606 OID 131569)
-- Name: carreras_en_curso unique_todos_carreras; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras_en_curso
    ADD CONSTRAINT unique_todos_carreras UNIQUE (placa, id_taxista, fecha_carrera, num_cel_u);


--
-- TOC entry 2849 (class 2606 OID 123409)
-- Name: carrera unique_usuario_carrera; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carrera
    ADD CONSTRAINT unique_usuario_carrera UNIQUE (num_cel_u, fecha_carrera);


--
-- TOC entry 2869 (class 2606 OID 131571)
-- Name: carreras_en_curso unique_usuario_carreras; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras_en_curso
    ADD CONSTRAINT unique_usuario_carreras UNIQUE (num_cel_u, fecha_carrera);


--
-- TOC entry 2827 (class 2606 OID 123066)
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (num_cel_u);


--
-- TOC entry 2891 (class 2620 OID 139746)
-- Name: carrera abonar_carrera; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER abonar_carrera AFTER INSERT ON public.carrera FOR EACH ROW EXECUTE PROCEDURE public.abonar_carrera();


--
-- TOC entry 2886 (class 2620 OID 148004)
-- Name: usuario borrar_usuario; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER borrar_usuario BEFORE DELETE ON public.usuario FOR EACH ROW EXECUTE PROCEDURE public.borrar_usuario();


--
-- TOC entry 2892 (class 2620 OID 139747)
-- Name: carrera cobrar_carrera; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER cobrar_carrera AFTER INSERT ON public.carrera FOR EACH ROW EXECUTE PROCEDURE public.cobrar_carrera();


--
-- TOC entry 2893 (class 2620 OID 131593)
-- Name: carreras_en_curso registrar_carrera; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER registrar_carrera BEFORE DELETE ON public.carreras_en_curso FOR EACH ROW EXECUTE PROCEDURE public.registrar_carrera();


--
-- TOC entry 2890 (class 2620 OID 147995)
-- Name: dir_fav registrar_fecha_dir_fav; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER registrar_fecha_dir_fav AFTER INSERT ON public.dir_fav FOR EACH ROW EXECUTE PROCEDURE public.registrar_fecha_dir_fav();


--
-- TOC entry 2888 (class 2620 OID 123252)
-- Name: taxi registrar_fecha_taxi; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER registrar_fecha_taxi AFTER INSERT ON public.taxi FOR EACH ROW EXECUTE PROCEDURE public.registrar_fecha_taxi();


--
-- TOC entry 2889 (class 2620 OID 147997)
-- Name: taxista registrar_fecha_taxista; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER registrar_fecha_taxista AFTER INSERT ON public.taxista FOR EACH ROW EXECUTE PROCEDURE public.registrar_fecha_taxista();


--
-- TOC entry 2887 (class 2620 OID 123248)
-- Name: usuario registrar_fecha_usuario; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER registrar_fecha_usuario AFTER INSERT ON public.usuario FOR EACH ROW EXECUTE PROCEDURE public.registrar_fecha_usuario();


--
-- TOC entry 2880 (class 2606 OID 123508)
-- Name: registro fk1_; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registro
    ADD CONSTRAINT fk1_ FOREIGN KEY (placa) REFERENCES public.taxi(placa) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2873 (class 2606 OID 147998)
-- Name: carrera fk1_carrera; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carrera
    ADD CONSTRAINT fk1_carrera FOREIGN KEY (num_cel_u) REFERENCES public.usuario(num_cel_u) ON UPDATE CASCADE;


--
-- TOC entry 2882 (class 2606 OID 131572)
-- Name: carreras_en_curso fk1_carreras; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras_en_curso
    ADD CONSTRAINT fk1_carreras FOREIGN KEY (num_cel_u) REFERENCES public.usuario(num_cel_u) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2870 (class 2606 OID 147938)
-- Name: dir_fav fk1_dir_fav; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dir_fav
    ADD CONSTRAINT fk1_dir_fav FOREIGN KEY (num_cel_u) REFERENCES public.usuario(num_cel_u) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2877 (class 2606 OID 123319)
-- Name: puntaje_log fk1_log; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.puntaje_log
    ADD CONSTRAINT fk1_log FOREIGN KEY (id_taxista) REFERENCES public.taxista(id_taxista);


--
-- TOC entry 2871 (class 2606 OID 123380)
-- Name: reporte fk1_reporte_taxi; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reporte
    ADD CONSTRAINT fk1_reporte_taxi FOREIGN KEY (placa) REFERENCES public.taxi(placa) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2878 (class 2606 OID 123390)
-- Name: taxistas_en_servicio fk1_td_taxi; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.taxistas_en_servicio
    ADD CONSTRAINT fk1_td_taxi FOREIGN KEY (placa) REFERENCES public.taxi(placa) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2879 (class 2606 OID 123395)
-- Name: taxistas_en_servicio fk1_td_taxista; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.taxistas_en_servicio
    ADD CONSTRAINT fk1_td_taxista FOREIGN KEY (id_taxista) REFERENCES public.taxista(id_taxista) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2874 (class 2606 OID 148005)
-- Name: carrera fk2_carrera; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carrera
    ADD CONSTRAINT fk2_carrera FOREIGN KEY (id_tarifa) REFERENCES public.tarifa(id_tarifa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2883 (class 2606 OID 131577)
-- Name: carreras_en_curso fk2_carreras; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras_en_curso
    ADD CONSTRAINT fk2_carreras FOREIGN KEY (id_tarifa) REFERENCES public.tarifa(id_tarifa) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2872 (class 2606 OID 123385)
-- Name: reporte fk2_reporte_taxista; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reporte
    ADD CONSTRAINT fk2_reporte_taxista FOREIGN KEY (id_taxista) REFERENCES public.taxista(id_taxista) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2875 (class 2606 OID 148010)
-- Name: carrera fk3_carrera; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carrera
    ADD CONSTRAINT fk3_carrera FOREIGN KEY (placa) REFERENCES public.taxi(placa) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2884 (class 2606 OID 131582)
-- Name: carreras_en_curso fk3_carreras; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras_en_curso
    ADD CONSTRAINT fk3_carreras FOREIGN KEY (placa) REFERENCES public.taxi(placa) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2876 (class 2606 OID 148015)
-- Name: carrera fk4_carrera; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carrera
    ADD CONSTRAINT fk4_carrera FOREIGN KEY (id_taxista) REFERENCES public.taxista(id_taxista) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 2885 (class 2606 OID 131587)
-- Name: carreras_en_curso fk4_carreras; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.carreras_en_curso
    ADD CONSTRAINT fk4_carreras FOREIGN KEY (id_taxista) REFERENCES public.taxista(id_taxista) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2881 (class 2606 OID 123513)
-- Name: registro pk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.registro
    ADD CONSTRAINT pk2 FOREIGN KEY (id_taxista) REFERENCES public.taxista(id_taxista) ON UPDATE CASCADE ON DELETE CASCADE;
