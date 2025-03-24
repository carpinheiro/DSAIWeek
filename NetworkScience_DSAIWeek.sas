cas;

caslib _all_ assign;

%let dl = /mnt/azure-files/homes/Carlos.Pinheiro@sas.com/ParisLines;

%let dm = /mnt/azure-files/homes/Carlos.Pinheiro@sas.com/ParisMaps;

%let dmng = /mnt/azure-files/homes/Carlos.Pinheiro@sas.com/NetSciGraphs;

%let dma = /mnt/azure-files/homes/Carlos.Pinheiro@sas.com/Asheville;

%include '/mnt/azure-files/homes/Carlos.Pinheiro@sas.com/CPNetGNL.sas';

%include '/mnt/azure-files/homes/Carlos.Pinheiro@sas.com/CPMapGNL.sas';

%include '/mnt/azure-files/homes/Carlos.Pinheiro@sas.com/DataSetsLesMiserables.sas';

%include '/mnt/azure-files/homes/Carlos.Pinheiro@sas.com/LoadDataParisMetroLines.sas';

%CPNetGNL(dir=&dmng,nodes=casuser.lmnodes,nn=node,nl=label,links=casuser.lmlinks,f=from,t=to,v=weight,fn=LesMiserables);

/* --------- */
/* subgraphs */
/* --------- */

/* connected components */

proc network
	direction = undirected
	nodes = casuser.lmnodes
	links = casuser.lmlinks
	outlinks = casuser.outlinks
	outnodes = casuser.outnodes
	;
	nodesvar
		node = node
		vars = (label)
	;
	linksvar
		from = from
		to = to
		weight = weight
	;
	connectedcomponents
		out = casuser.concompout
	;
run;

%CPNetGNL(dir=&dmng,nodes=casuser.outnodes,nn=node,nl=label,ng=concomp,links=casuser.outlinks,f=from,t=to,v=weight,g=concomp,fn=concomp);

/* biconnected components */

proc network
	direction = undirected
	nodes = casuser.lmnodes
	links = casuser.lmlinks
	outlinks = casuser.outlinks
	outnodes = casuser.outnodes
	;
	nodesvar
		node = node
		vars = (label)
	;
	linksvar
		from = from
		to = to
		weight = weight
	;
	biconnectedcomponents
		out = casuser.biconcompout
	;
run;

%CPNetGNL(dir=&dmng,nodes=casuser.outnodes,nn=node,nl=label,ng=artpoint,links=casuser.outlinks,f=from,t=to,v=weight,g=biconcomp,fn=artpoint);

data casuser.nodesap;
	set casuser.outnodes(where=(artpoint=0));
run;

proc sql;
	create table linksbc as
		select * from casuser.outlinks where from in (select node from casuser.nodesap) and to in (select node from casuser.nodesap);
quit;

data casuser.linksbc;
	set linksbc;
run;

proc network
	direction = undirected
	nodes = casuser.nodesap
	links = casuser.linksbc
	outlinks = casuser.outlinks
	outnodes = casuser.outnodes
	;
	nodesvar
		node = node
		vars = (label)
	;
	linksvar
		from = from
		to = to
		weight = weight
	;
	connectedcomponents
		out = casuser.concompout
	;
run;

%CPNetGNL(dir=&dmng,nodes=casuser.outnodes,nn=node,nl=label,ng=concomp,links=casuser.outlinks,f=from,t=to,v=weight,g=concomp,fn=biconcomp);

/* community detection */

proc network
	direction = undirected
	nodes = casuser.lmnodes
	links = casuser.lmlinks
	outlinks = casuser.outlinks
	outnodes = casuser.outnodes
	;
	nodesvar
		node = node
		vars = (label)
	;
	linksvar
		from = from
		to = to
		weight = weight
	;
	community 
		algorithm = louvain
		resolutionlist = 2.0 1.0 0.5
		outlevel = casuser.outcommlevel
		outcommunity = casuser.outcomm
		outoverlap = casuser.outoverlap
		outcommLinks = casuser.outcommlinks
	;
run;

%CPNetGNL(dir=&dmng,nodes=casuser.outnodes,nn=node,nl=label,ng=community_1,links=casuser.outlinks,f=from,t=to,v=weight,g=community_1,fn=comm1);
%CPNetGNL(dir=&dmng,nodes=casuser.outnodes,nn=node,nl=label,ng=community_2,links=casuser.outlinks,f=from,t=to,v=weight,g=community_2,fn=comm2);
%CPNetGNL(dir=&dmng,nodes=casuser.outnodes,nn=node,nl=label,ng=community_3,links=casuser.outlinks,f=from,t=to,v=weight,g=community_3,fn=comm3);

/* core */

proc network
	direction = undirected
	nodes = casuser.lmnodes
	links = casuser.lmlinks
	outnodes = casuser.outnodes
	;
	nodesvar
		node = node
		vars = (label)
	;
	linksvar
		from = from
		to = to
		weight = weight
	;
	core 
	;
run;

%CPNetGNL(dir=&dmng,nodes=casuser.outnodes,nn=node,nl=label,ng=core_out,links=casuser.lmlinks,f=from,t=to,v=weight,fn=core);

/* reach network */

data casuser.egonodes;
	set casuser.lmnodes(where=(node=11));
	reach=1; 
run;

proc network
	direction = undirected
	links = casuser.lmlinks
	nodessubset = casuser.egonodes
	;
	linksvar
		from = from
		to = to
		weight = weight
	;
	reach
		outreachlinks = casuser.outreachlinks
		outreachnodes = casuser.outreachnodes
		outcounts = casuser.outreachcounts
	;
run;

data casuser.nodesaux;
	merge casuser.outreachnodes(in=a)
		  casuser.lmnodes(in=b);
	by node;
	if a and b;
run;

%CPNetGNL(dir=&dmng,nodes=casuser.nodesaux,nn=node,nl=label,ng=reach,links=casuser.outreachlinks,f=from,t=to,v=weight,g=reach,fn=reach1);

proc network
	direction = undirected
	links = casuser.lmlinks
	nodessubset = casuser.egonodes
	;
	linksvar
		from = from
		to = to
		weight = weight
	;
	reach
		maxreach = 2
		outreachlinks = casuser.outreachlinks
		outreachnodes = casuser.outreachnodes
		outcounts = casuser.outreachcounts
	;
run;

data casuser.nodesaux;
	merge casuser.outreachnodes(in=a)
		  casuser.lmnodes(in=b);
	by node;
	if a and b;
run;

%CPNetGNL(dir=&dmng,nodes=casuser.nodesaux,nn=node,nl=label,ng=reach,links=casuser.outreachlinks,f=from,t=to,v=weight,g=reach,fn=reach2);

/* node similarity */

data casuser.links;
	input from $ to $ @@;
datalines;
A E A B A F A D A H A I D C F G 
T U T V T X T Y T R T S X W Y Z
E V B U
;
run;

proc network
	direction = undirected
	links = casuser.links
	outnodes = casuser.outnodesvectors
	;
	linksvar
		from = from
		to = to
	;
	nodesimilarity 
		commonneighbors = true
		jaccard = true
		cosine = true
		adamicadar = true
		vector = true
			ndimensions = 100
		proximityorder = second
		outsimilarity = casuser.outsimilarity
	;
run;

%CPNetGNL(dir=&dmng,links=casuser.links,f=from,t=to,fn=similarity);

data linkssimilar;
	set casuser.outsimilarity(where=(source<>sink and adamicAdar>0));
run;

%CPNetGNL(dir=&dmng,links=linkssimilar,f=source,t=sink,v=adamicAdar,fn=nodessimilarity);

/* pattern match */

data casuser.links;
	input from $ to $ weight @@;
datalines;
A B 5 B C 2 C D 3 D B 1 N A 3 A K 2 N K 4 M K 2 L K 1
A E 5 E H 1 H A 5 H I 6 H J 4 J I 7 E F 3 E G 2 F G 8
B N 5 N O 1 O P 2 P N 1 N Q 5 Q R 1 R S 4 Q S 2
;
run; 

data casuser.nodes;
	input node $ shape $ @@;
datalines;
A dot B dot C hexagon D square E dot F dot G dot
H diamond I hexagon J square K diamond L hexagon M square
N hexagon O hexagon P square Q dot R hexagon S square
;
run; 

%CPNetGNL(dir=&dmng,nodes=casuser.nodes,nn=node,nl=node,ns=shape,ng=shape,links=casuser.links,f=from,t=to,v=weight,fn=patternmatchnet);

data casuser.nodesquery;
	input node $ shape $ @@;
datalines;
1 hexagon
2 square
5 hexagon
6 square
;
run; 

data casuser.linksquery;
	input from $ to $ weight @@;
datalines;
1 2 .
2 3 .
3 1 .
3 4 5
4 5 .
5 6 .
6 4 .
;
run; 

proc sql;
	create table lnknd as
		select a.node, coalesce(b.shape,'star') as shape from
			(select from as node from casuser.linksquery
				union corr 
			select to as node from casuser.linksquery) as a
		left join casuser.nodesquery as b
			on a.node=b.node;
quit;

data lksquery;
	set casuser.linksquery;
	llw=weight;
	if weight=. then weight=1;
run;

%CPNetGNL(dir=&dmng,nodes=lnknd,nn=node,nl=node,ns=shape,ng=shape,links=lksquery,f=from,t=to,v=weight,l=llw,fn=patternmatchquery);

proc network
	direction = undirected
	nodes = casuser.nodes
	links = casuser.links
	nodesquery = casuser.nodesquery
	linksquery = casuser.linksquery
	;
	nodesvar
		node = node
		vars = (shape)
	;
	linksvar
		from = from
		to = to
		weight = weight
	;
	nodesqueryvar
		node = node
		vars = (shape)
	;
	linksqueryvar
		from = from
		to = to
		vars = (weight)
	;
	patternmatch
		outmatchnodes = casuser.outmatchnodes
		outmatchlinks = casuser.outmatchlinks;
run;

proc sql;
	create table nodesmatch as
		select distinct node, shape from casuser.outmatchnodes;
quit;

%CPNetGNL(dir=&dmng,nodes=nodesmatch,nn=node,nl=node,ns=shape,ng=shape,links=casuser.outmatchlinks,f=from,t=to,v=weight,fn=patternmatch);

/* -------------------- */
/* network centralities */
/* -------------------- */

proc network
	direction = undirected
	nodes = casuser.lmnodes
	links = casuser.lmlinks
	outlinks = casuser.outlinkscomm
	outnodes = casuser.outnodescomm
	;
	linksvar
		from = from
		to = to
		weight = weight
	;
	community
		algorithm = louvain
		resolution_list = 1
	;
run;

/* by community */

proc network
	direction = undirected
	links = casuser.outlinkscomm(where=(community_1 ne .))
	outlinks = casuser.outlinks
	outnodes = casuser.outnodes
	;
	linksvar
		from = from
		to = to
		weight = weight
	;
	centrality
		degree
		influence = weight
		clusteringcoef
		close = weight
			closenopath = diameter		
		between = weight
			betweennorm = true
		eigen = weight
		pagerank = weight
			pagerankalpha = 0.85
	;
	by community_1
	;
run;

data casuser.nodeslm;
	merge casuser.outnodes(in=a) 
		  casuser.lmnodes(in=b);
	by node;
	if a and b;
run;

%CPNetGNL(dir=&dmng,nodes=casuser.nodeslm,nn=node,nl=label,nv=centr_influence1_wt,ng=community_1,links=casuser.outlinks,f=from,t=to,v=weight,g=community_1,fn=centralitycomm);

/* entire network */

proc network
	direction = undirected
	links = casuser.lmlinks
	outlinks = casuser.outlinks
	outnodes = casuser.outnodes
	;
	linksvar
		from = from
		to = to
		weight = weight
	;
	centrality
		degree
		influence = weight
		clusteringcoef
		close = weight
			closenopath = diameter		
		between = weight
			betweennorm = true
		eigen = weight
		pagerank = weight
			pagerankalpha = 0.85
	;
run;

data casuser.nodeslm;
	merge casuser.lmnodes(in=a) 
		  casuser.outnodescomm(in=b) 
		  casuser.outnodes(in=c);
	by node;
	if a and b and c;
run;

%CPNetGNL(dir=&dmng,nodes=casuser.nodeslm,nn=node,nl=label,nv=centr_influence1_wt,ng=community_1,links=casuser.lmlinks,f=from,t=to,v=weight,g=community_1,fn=centrality);

/* -------------------- */
/* network optimization */
/* -------------------- */

/* linear assignment */

data casuser.chairs; 
   input employee $ leg arm seat back; 
datalines; 
John 14 18 23 27
Clark 12 14 19 22
Megan 15 17 28 25
Paul 21 25 32 19
Beth 16 20 22 28
Lisa 13 21 20 32
Linda 15 19 25 29 
Mike 15 16 24 26
;
run;

data casuser.chairslinks(keep=employee part cost);
	set casuser.chairs;
	length part $ 4;
	array a[4] leg arm seat back;
	do i=1 to dim(a);
		part=vname(a[i]);
		cost=a[i];
		output;
	end;
run;

proc optnetwork
	direction = directed 
	links = casuser.chairslinks
	;
	linksvar
		from = employee
		to = part
		weight = cost
	;
	linearassignment
		out = casuser.outlap
	;
run;

%CPNetGNL(dir=&dmng,links=casuser.chairslinks,f=employee,t=part,v=cost,fn=linearassign);

/* minimum-cost network flow */

data casuser.nodes;
	input node supdem;
datalines;
1 10
2 20
3 0
4 -5
5 0
6 0
7 -15
8 -10
;
run;

data casuser.links;
	input from to cost max;
datalines;
1 4 2 15
2 1 1 10
2 3 0 10
2 6 6 10
3 4 1 5
3 5 4 10
4 7 5 10
5 6 2 20
5 7 7 15
6 8 8 10
7 8 9 15
;
run;

proc optnetwork 
	direction = directed
	links = casuser.links
	nodes = casuser.nodes
	outlinks = casuser.linksoutmcnf
	outnodes = casuser.nodesoutmcnf
	;
	linksvar
		from = from
		to = to
		weight = cost
		upper = max
	;
	nodesvar
		node = node
		lower = supdem
	;
	mincostflow
	;
run;

%CPNetGNL(dir=&dmng,links=casuser.linksoutmcnf,f=from,t=to,v=mcf_flow,fn=mincostnetflow);

/* ----------------- */
/* Paris metro lines */
/* ----------------- */

%let latitude=48.856358;
%let longitude=2.351632;
%let zoom=14;

%CPMapGNL(dir=&dm,d=casuser.lines,clt=&latitude,clg=&longitude,cz=&zoom,lt=stop_lat,lg=stop_lon,v=5,ll=line,lc=color,m=poly,fn=metrolines);

/* clique */

proc optnetwork
	direction = undirected
	links = casuser.metrolinks
	;
	linksvar
		from = org
		to = dst
		weight = dist
	;
	clique
		maxcliques = all
		minsize = 3
		out = casuser.cliquemetro
	;
run;

proc sql;
	create table cliquemetro as
		select distinct a.node, a.clique, b.lat as stop_lat, b.lon as stop_lon, '#000000' as color, compress('CL'||put(a.clique,4.)) as line 
			from casuser.cliquemetro as a 
				inner join metronodes as b 
					on a.node = b.node
						order by a.clique;
quit;

data cliques;
	set casuser.lines cliquemetro;
	if clique=. then
		do;
			wln=3;
			plg=0;
		end;
	else
		do;
			wln=8;
			plg=1;
		end;
run;

%CPMapGNL(dir=&dm,d=cliques,clt=&latitude,clg=&longitude,cz=&zoom,lt=stop_lat,lg=stop_lon,v=wln,p=plg,ll=line,lc=color,m=poly,fn=metrocliques);

/* cycle */

proc optnetwork
	direction = directed
	links = casuser.metrolinks
	;
	linksvar
		from = org
		to = dst
		weight = dist
	;
	cycle
		algorithm = build
		maxcycles = all
		minlength = 3
		maxlength = 20
		out = casuser.cyclemetro
	;
run;

proc sql;
	create table cyclemetro as
		select distinct a.node, a.cycle, a.order, b.lat as stop_lat, b.lon as stop_lon, '#000000' as color, compress('CY'||put(a.cycle,4.)) as line 
			from casuser.cyclemetro as a 
				inner join metronodes as b 
					on a.node = b.node
						order by a.cycle;
quit;

data cycles;
	set casuser.lines cyclemetro;
	if cycle=. then
		do;
			wln=3;
			plg=0;
		end;
	else
		do;
			wln=8;
			plg=1;
		end;
run;

%CPMapGNL(dir=&dm,d=cycles,clt=&latitude,clg=&longitude,cz=&zoom,lt=stop_lat,lg=stop_lon,v=wln,p=plg,ll=line,lc=color,m=poly,fn=metrocycles);

/* maximum network flow */

proc optnetwork
	direction = directed
	links = casuser.metrolinksdirected
	;
	linksvar
		from = org
		to = dst
		weight = dist
	;
	path
		source = 'La Plaine-Stade de France'
		sink = 'Châtelet-Les Halles'
		maxlength = 10
		outpathslinks = casuser.pathmetromnf
	;
run;

proc sql;
	create table mnfpaths as
		select a.*, b.* from casuser.metrolinksdirected as a
			inner join casuser.pathmetromnf as b
				on a.org=b.org and a.dst=b.dst 
					order by b.path, b.order;
quit;

data casuser.mnfpathscapacity;
	set mnfpaths;
	capacity=200;
	if line in ('1','4') then capacity=600;
	if line='14' then capacity=800;
	if line in ('2','3','3b','5','6','7','7b','8','9','10','11','12','13') then capacity=500;
	if line in ('A','B') then capacity=2600;
	if line='orv' then capacity=50;
run;

proc optnetwork
	direction = directed
	links = casuser.mnfpathscapacity
	outLinks = casuser.linksoutmnf
	;
	linksvar
		from = org
		to = dst
		upper = capacity
		vars = (_all_)
	;
	maxflow
		source = 'La Plaine-Stade de France'
		sink = 'Châtelet-Les Halles'
	;
run;

%CPMapGNL(dir=&dm,d=casuser.linksoutmnf,clt=&latitude,clg=&longitude,cz=&zoom,l=org,lt=org_lat,lg=org_lon,ld=dst,ltd=dst_lat,lgd=dst_lon,ll=line,v=mf_flow/250,lc=color,m=line,fn=metromaxflow);

/* minimum spanning tree */

proc optnetwork
	direction = undirected
	links = casuser.metrolinks
	;
	linksvar
		from = org
		to = dst
		weight = dist
	;
	minspantree
		out = casuser.minspantreemetro
	;
run;

proc sql;
	create table minspantreemetro as
		select distinct a.org, a.dst, b.org_lat, b.org_lon, b.dst_lat, b.dst_lon, b.color, b.line
			from casuser.minspantreemetro as a 
				inner join casuser.metrolinks as b  
					on a.org = b.org and a.dst = b.dst;
quit;

data minspantree;
	set casuser.metrolinks minspantreemetro;
	if dist=. then
		axvl=6;
	else
		axvl=2;
run;

%CPMapGNL(dir=&dm,d=minspantree,clt=&latitude,clg=&longitude,cz=&zoom,lt=org_lat,lg=org_lon,ltd=dst_lat,lgd=dst_lon,v=axvl,lc=color,m=line,fn=metrospantree);

/* path */

proc optnetwork
	direction = directed
	links = casuser.metrolinksdirected
	;
	linksvar
		from = org
		to = dst
		weight = dist
	;
	path
		source = Volontaires
		sink = Nation
		maxlength = 20
		outpathslinks = casuser.pathmetro
	;
run;

proc sql;
	create table pathmetro as
		select distinct a.path, a.source, a.sink, a.order, a.org, a.dst, b.org_lat, b.org_lon, b.dst_lat, b.dst_lon, b.color, b.line
			from casuser.pathmetro as a 
				inner join casuser.metrolinksdirected as b  
					on a.org = b.org and a.dst = b.dst
						order by a.path, a.order;
quit;

%CPMapGNL(dir=&dm,d=pathmetro,clt=&latitude,clg=&longitude,cz=&zoom,l=org,lt=org_lat,lg=org_lon,ld=dst,ltd=dst_lat,lgd=dst_lon,v=3,o="Volontaires",od="Nation",lm=2,lc=color,m=line,fn=metropath);

/* shortest path */

proc optnetwork
	direction = directed
	links = casuser.metrolinksdirected
	;
	linksvar
		from = org
		to = dst
		weight = dist
	;
	shortestpath
		source = Volontaires
		sink = Nation
		outpaths = casuser.shortpathmetro
	;
run;

proc sql;
	create table shortestpathmetrotmp as
		select distinct a.*, b.* from casuser.shortpathmetro as a 
			inner join casuser.metrolinksdirected as b  
				on a.org = b.org and a.dst = b.dst
					order by a.order;
quit;

data shortestpathmetro;
	ao = order;
	set shortestpathmetrotmp;
	if ao ne order then
		do;
			drop ao;
			output;
		end;
run;

%CPMapGNL(dir=&dm,d=shortestpathmetro,clt=&latitude,clg=&longitude,cz=&zoom,l=org,lt=org_lat,lg=org_lon,ld=dst,ltd=dst_lat,lgd=dst_lon,v=4,o="Volontaires",od="Nation",lm=2,lc=color,m=line,fn=metroshortpath);

/* traveling salesman problem */

/* points of interest */

data places;
	length name $20;
	infile datalines delimiter=",";
	input name $ x y;
datalines;
Novotel,48.860886,2.346407
Tour Eiffel,48.858093,2.294694
Louvre,48.860819,2.33614
Jardin des Tuileries,48.86336,2.327042
Trocadero,48.861157,2.289276
Arc de Triomphe,48.873748,2.295059
Jardin du Luxembourg,48.846658,2.336451
Fontaine Saint Michel,48.853218,2.343757
Notre-Dame,48.852906,2.350114
Le Marais,48.860085,2.360859
Les Halles,48.862371,2.344731
Sacre-Coeur,48.88678,2.343011
Musee dOrsay,48.859852,2.326634
Opera,48.87053,2.332621
Pompidou,48.860554,2.352507
Tour Montparnasse,48.842077,2.321967
Moulin Rouge,48.884124,2.332304
Pantheon,48.846128,2.346117
Hotel des Invalides,48.856463,2.312762
Madeleine,48.869853,2.32481
Quartier Latin,48.848663,2.342126
Bastille,48.853156,2.369158
Republique,48.867877,2.363756
Canal Saint-Martin,48.870834,2.365655
Place des Vosges,48.855567,2.365558
Luigi Pepone,48.841696,2.308398
Josselin,48.841711,2.325384
The Financier,48.842607,2.323681
Berthillon,48.851721,2.35672
The Frog & Rosbif,48.864309,2.350315
Moonshiner,48.855677,2.371183
Cafe de lIndustrie,48.855655,2.371812
Chez Camille,48.84856,2.378099
Beau Regard,48.854614,2.333307
Maison Sauvage,48.853654,2.338045
Les Negociants,48.837129,2.351927
Les Cailloux,48.827689,2.34934
Cafe Hugo,48.855913,2.36669
La Chaumiere,48.852816,2.353542
Cafe Gaite,48.84049,2.323984
Au Trappiste,48.858295,2.347485
;
run;

%CPMapGNL(dir=&dm,d=places,clt=&latitude,clg=&longitude,cz=&zoom,l=name,lt=x,lg=y,m=marker,fn=parisplaces);

/* identify all possible connections between the places to visit */

proc sql;
	create table placeslinktmp as
		select a.name as org, a.x as xorg, a.y as yorg, b.name as dst, b.x as xdst, b.y as ydst 
			from places as a, places as b;
quit;

data placeslink;
	set placeslinktmp;
	if org ne dst then
		output;
run;

%CPMapGNL(dir=&dm,d=placeslink,clt=&latitude,clg=&longitude,cz=&zoom,lt=xorg,lg=yorg,ltd=xdst,lgd=ydst,m=line,fn=parisvectors);

/* compute the Euclidian distance between all pairs of locations */

data casuser.placesdist;
	set placeslink;
	distance=geodist(xdst,ydst,xorg,yorg,'K');
	output;
run;

/* network optimization - compute the optimal tour based on a walking tour */

proc optnetwork
	direction = directed
	links = casuser.placesdist
	out_nodes = casuser.placesnodes
	;
	linksvar
		from = org
		to = dst
		weight = distance
	;
	tsp
		cutstrategy = none
		heuristics = none
		milp = true
		out = casuser.placesTSP
	;
run;

/* select the right sequence of the tour staring and ending at the hotel */

data steps;
	set casuser.placestsp casuser.placestsp;
run;

data stepsstart;
	set steps;
	if org = 'Novotel' then	
		k+1;
	if k = 1 then
		do;
			drop k;
			output;
			if dst = 'Novotel' then
				K+1;
		end;
run;

/* calculate distance and time for the walk tour */

proc sql;
	select sum(distance), sum(distance)/5 from stepsstart;
quit;

/* create the HTML file with the best walk tour */

proc sql;
	create table placestour as
		select c.org, c.xorg, c.yorg, c.dst, d.x as xdst, d.y as ydst from
			(select a.org, b.x as xorg, b.y as yorg, a.dst
				from stepsstart as a 
					inner join places as b 
						on a.org = b.name) as c
				inner join places as d 
					on c.dst = d.name;
quit;

%CPMapGNL(dir=&dm,d=placestour,clt=&latitude,clg=&longitude,cz=&zoom,l=org,lt=xorg,lg=yorg,ld=dst,ltd=xdst,lgd=ydst,o='Novotel',m=tour,fn=paristsp);

/* travelling salesman problem - multimodal transportation system */

/* comuting distances between places and between places and stations */

proc sql;
	create table placesstations as
		select a.name as place, a.x as xp, a.y as yp, b.node as station, b.lat as xs, b.lon as ys 
			from places as a, metronodes as b;
quit;

data placesstationsdist;
	set placesstations;
	distance=geodist(xs,ys,xp,yp,'K');
	output;
run;

proc sort data=placesstationsdist;
	by place distance;
run;

data stationplace;
	length ap $20.;
	ap=place;
	set placesstationsdist;
	if ap ne place then 
		do;
			drop ap;
			output;
		end;
run;

/* calculate distances between places and places and stations */

proc sql;
	create table stationplacelinktmp as
		select a.place as plorg, a.xp as xporg, a.yp as yporg, a.station as storg, a.xs as xsorg, a.ys as ysorg, a.distance as distorg,
 				b.place as pldst, b.xp as xpdst, b.yp as ypdst, b.station as stdst, b.xs as xsdst, b.ys as ysdst, b.distance as distdst
			from stationplace as a, stationplace as b;
quit;

data stationplacelink;
	set stationplacelinktmp;
	if plorg ne pldst then
		output;
run;

/* comparing when to walk and when to take transportation based on the distance between locations */

data casuser.stationplacelinkdist;
	set stationplacelink;
	pldist=geodist(xporg,yporg,xpdst,ypdst,'K');
	stdist=geodist(xsorg,ysorg,xsdst,ysdst,'K');
	if pldist lt (distorg+distdst) then
		do;
			distance=pldist;
			type='W';
		end;
	else
		do;
			distance=distorg+stdist+distdst;
			type='T';
		end;
	output;
run;

/* calculate the optimal tour based on multimodal transportation network */

proc optnetwork
	direction = directed
	links = casuser.stationplacelinkdist
	out_nodes = casuser.stationplacenodes
	;
	linksvar
		from = plorg
		to = pldst
		weight = distance
	;
	tsp
		cutstrategy = none
		heuristics = none
		milp = true
		out = casuser.stationplaceTSP
	;
run;

/* select the right sequence of the tour staring and ending at the hotel */

data stationplacestep;
	set casuser.stationplacetsp casuser.stationplacetsp;
run;

data stationplacestepstart;
	set stationplacestep;
	if plorg = 'Novotel' then	
		k+1;
	if k = 1 then
		do;
			order+1;
			drop k;
			output;
			if pldst = 'Novotel' then
				K+1;
		end;
run;

proc sql;
	create table stationplacetour as
		select a.order, b.* from stationplacestepstart as a 
			inner join casuser.stationplacelinkdist as b 
				on a.plorg = b.plorg and a.pldst = b.pldst
					order by a.order;
quit;

/* calculate all shortest paths by pairs of locations within the tour when taking the public transportation */

data stationplaceW stationplaceT;
	set stationplacetour;
	if type = 'W' then
		output stationplaceW;
	else 
		output stationplaceT;
run;

proc optnetwork
	direction = undirected
	links = casuser.metrolinks
	;
	linksvar
		from = org
		to = dst
		weight = dist
	;
	shortestpath
		outpaths = casuser.shortpathmetrotour
	;
run;

/* define all sequences from the shortest paths for the public transportation */

proc sql;
	create table stpltoursp as
		select a.*, b.source as source, b.sink as sink, b.order as suborder, b.org as org, b.dst as dst, b.dist as dist 
			from stationplacet as a
				inner join casuser.shortpathmetrotour as b
					on a.storg = b.source and a.stdst = b.sink
						order by a.order, b.order;
quit;

data stpltourspseq;
	set stationplaceW stpltoursp;
run;

proc sql;
	create table stationplacetourfinaltmp as
		select a.*, b.line, b.color, b.org_lat, b.org_lon, b.dst_lat, b.dst_lon
			from stpltourspseq as a
				left join metrolinksdirected as b  
					on a.org = b.org and a.dst = b.dst
						order by order, suborder, line;
quit;

/* joining all steps for the optimal tour: walking and shortest path for public transportation */

data stationplacetourfinal;
	length po $50. pd $50. cl $7.;
	set stationplacetourfinaltmp;
	if type eq 'W' then
		do;
			po=plorg;
			xo=xporg;
			yo=yporg;
			pd=pldst;
			xd=xpdst;
			yd=ypdst;
			cl='maroon';
			ls='d';
			omc='m';
			dmc='m';
			output;
		end;
	else
		if suborder eq 1 then
			do;
				po=plorg;
				xo=xporg;
				yo=yporg;
				pd='';
				xd=xsorg;
				yd=ysorg;
				cl='#800000';
				ls='d';
				omc='m';
				dmc='c';
				output;
				po=pldst;
				xo=xpdst;
				yo=ypdst;
				pd='';
				xd=xsdst;
				yd=ysdst;
				cl='#800000';
				ls='d';
				omc='m';
				dmc='c';
				output;
				po='';
				xo=org_lat;
				yo=org_lon;
				pd='';
				xd=dst_lat;
				yd=dst_lon;
				cl=color;
				ls='';
				omc='c';
				dmc='c';
				output;
			end;
		else
			do;
				po='';
				xo=org_lat;
				yo=org_lon;
				pd='';
				xd=dst_lat;
				yd=dst_lon;
				cl=color;
				ls='';
				omc='c';
				dmc='c';
				output;
			end;
run;

%CPMapGNL(dir=&dm,d=stationplacetourfinal,clt=&latitude,clg=&longitude,cz=&zoom,l=po,lt=xo,lg=yo,ld=pd,ltd=xd,lgd=yd,v=5,lc=cl,ls=ls,omc=omc,dmc=dmc,o='Novotel',m=tour,fn=paristour);

/* calculate distance and time for the multimodal walk tour */

data metrolinks;
	set casuser.metrolinks;
run;

data stpltour;
	set metrolinks stationplacetourfinal;
run;

proc sql;
	select sum(distance) from stationplacetourfinal where type='W';
quit;

proc sql;
	select sum(time), sum(distance) from 
		(select case when type='W' then distance/5 
					when type='T' then distance/25.1 end as time, type, distance from  
			(select type, coalesce(sum(dist),sum(distance)) as distance
				from stationplacetourfinal 
					group by type));
quit;

/* vehicle routing problem  */

/* points of interest */

%let latitude=35.59560349262985;
%let longitude=-82.55167448601539;
%let zoom=14;
%let Start='Zillicoach Beer';
%let depot='Zillicoach Beer';
%let trucks=1;
%let capacity=23;

data places;
	length place $20;
	infile datalines delimiter=",";
	input place $ lat long demand;
datalines;
Zillicoach Beer,35.61727324024679,-82.57620125854477,12
Barleys Taproom, 35.593508941040184,-82.55049904390695,6
Foggy Mountain,35.594499248395294,-82.55286640671683,10
Jack of the Wood,35.5944656344917,-82.55554641291447,4
Asheville Club,35.595301953719876,-82.55427884441883,7
The Bier Graden,35.59616807405638,-82.55487446973056,10
Bold Rock,35.596168519758706,-82.5532906435109,9
Packs Tavern,35.59563366969523,-82.54867278235423,12
Bottle Riot,35.586701815340874,-82.5664137278939,5
Hillman Beer,35.5657625849887,-82.53578181164393,6
Westville Pub,35.5797705582317,-82.59669352112562,8
District 42,35.59575560112859,-82.55142220123702,10
Workshop Lounge,35.59381883030113,-82.54921206099571,4
TreeRock Social,35.57164142260938,-82.54272668032107,6
The Whale,35.57875963366179,-82.58401015401363,2
Avenue M,35.62784935175343,-82.54935140167011,4
Pillar Rooftop,35.59828820775747,-82.5436137644324,3
The Bull and Beggar,35.58724435501913,-82.564799389471,8
Jargon,35.5789624127538,-82.5903739015448,1
The Admiral,35.57900392043434,-82.57730888246586,1
Vivian,35.58378161962331,-82.56201676356083,1
Corner Kitchen,35.56835364052998,-82.53558091251179,1
;
run;

%CPMapGNL(dir=&dma,d=places,clt=&latitude,clg=&longitude,cz=&zoom,l=place,lt=lat,lg=long,t=type,v=demand,o=&depot,lv='Trucks=',vv=&trucks,lsd='Capacity=',vsd=&capacity,m=marker,fn=places);

/* identify all possible connections between the places to visit */

proc sql;
	create table placeslink as
		select a.place as org, a.lat as latorg, a.long as longorg, b.place as dst, b.lat as latdst, b.long as longdst 
			from places as a, places as b
				where a.place<b.place;
quit;

/* compute the Euclidian distance between all pairs of locations */

data casuser.links;
	set placeslink;
	distance=geodist(latdst,longdst,latorg,longorg,'M');
	output;
run;

/* vehicle routing problem */

data casuser.nodes;
	set places(where=(place ne &depot));
run;

proc optnetwork
	direction = undirected
	links = casuser.links
	nodes = casuser.nodes
	outnodes = casuser.nodesout;
	linksvar
		from = org
		to = dst
		weight = distance
	;
	nodesvar
		node = place
		lower = demand
		vars=(lat long)
	;
	vrp
		depot = &depot

		minroutes = 1
		maxroutes = 50

		capacity = &capacity
		out = casuser.routes;
run;

proc sql;
	create table routing as
		select a.place, a.demand, case when a.route=. then 1 else a.route end as route, a.route_order, b.lat, b.long
			from casuser.nodesout as a
				inner join places as b
					on a.place=b.place
			order by route, route_order; 
quit;

proc sql noprint;
	select place, lat, long into :d, :latd, :longd from routing where demand=.;
quit;

proc sql noprint;
	select max(route)/&trucks+0.1 into :t from routing;
quit;

%CPMapGNL(dir=&dma,d=routing,clt=&latitude,clg=&longitude,cz=&zoom,l=place,lt=lat,lg=long,v=demand,r=route,s=route_order,i=true,m=route,fn=vrp);
